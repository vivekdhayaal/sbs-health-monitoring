import java.io.BufferedReader;
import java.io.FileReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;

class ResourceUnavailableException extends RuntimeException
{
    public ResourceUnavailableException(String message)
    {
        super(message);
    }
}


class Race extends Thread
{
   private String cmd;
   private int st;
   private StringBuilder sb = new StringBuilder();
   Race(String n, String v, int t)
   {
     // 'n' is the thread name. It would be one of the below values
     // t0 - setup thread
     // t1 - test case 1's thread
     // t2 - test case 2's thread
     // tn - cleanup thread
     super(n);
     this.cmd = v;
     this.st = t;
     //start();
   }
   public void run()
   {
        this.sb.append("Command: " + this.cmd + "\n");
        String s;
        Process p;
        try {
            p = Runtime.getRuntime().exec(this.cmd);
            BufferedReader br = new BufferedReader(
                new InputStreamReader(p.getInputStream()));
            this.sb.append(this.getName() + "stdout=====: ");
            while ((s = br.readLine()) != null) {
              this.sb.append(this.getName() + "line: " + s);
              this.sb.append(System.getProperty("line.separator"));
            }
            BufferedReader stdError = new BufferedReader(
                new InputStreamReader(p.getErrorStream()));
            this.sb.append(this.getName() + "stderr=====: ");
            while ((s = stdError.readLine()) != null) {
              this.sb.append(this.getName() + s);
              this.sb.append(System.getProperty("line.separator"));
            }
            p.waitFor();
            //System.out.println (this.getName() + "exit: " + p.exitValue());
            p.destroy();
        } catch (Exception e) {
             e.printStackTrace();  
             System.out.println(this.getName() + "ERROR.RUNNING.BELOW.CMD");  
        }
        System.out.println(this.sb);
   }

   public String getSb() {
     return this.sb.toString();
   }
}

class Test
{
   private int MAX_RETRIES = 60;
   private String instanceId = null;
   private String volumeId = null;
   private String snapshotId = null;
   private String size;
   private String defaultSize;
   private boolean volumeAttached = false;
   private List<String> allVolumes = new ArrayList<String>();
   private List<String> allSnapshots = new ArrayList<String>();
   private List<String> allInstances = new ArrayList<String>();
   private boolean UseSnapshotId = false;
   private boolean UseAttachedVolume = false;
   private boolean UseDifferentInstance = false;
   private String createVolCmd = "jcs compute CreateVolume ";
   private String descVolCmd = "jcs compute DescribeVolumes --VolumeId ";
   private String detachVolCmd = "jcs compute DetachVolume ";
   private String deleteVolCmd = "jcs compute DeleteVolume --VolumeId ";
   private String deleteSnapCmd = "jcs compute DeleteSnapshot --SnapshotId ";

   public void setDefaultSize(String size)
   {
    this.defaultSize = size;
    this.size = this.defaultSize;
   }

   public void setTestLocalSize(String specsStr)
   {
     String[] specs = specsStr.split("=");
     this.size = specs[1];
   }

   public void setUseSnapshotId()
   {
    this.UseSnapshotId = true;
   }

   public void setUseAttachedVolume()
   {
    this.UseAttachedVolume = true;
   }

   public void setUseDifferentInstance()
   {
    this.UseDifferentInstance = true;
   }

   public boolean isUseSnapshotId()
   {
    return this.UseSnapshotId;
   }

   public boolean isUseAttachedVolume()
   {
    return this.UseAttachedVolume;
   }

   public boolean isUseDifferentInstance()
   {
    return this.UseDifferentInstance;
   }

   public List<String> getAllInstances()
   {
    return this.allInstances;
   }

   public void resetOpts()
   {
    this.size = this.defaultSize;
    this.UseSnapshotId = false;
    this.UseAttachedVolume = false;
    this.UseDifferentInstance = false;
   }

   public void waitForThreadCompletion(Race race)
   {
       try
       {
          while(race.isAlive())
          {
            System.out.println("Waiting a sec for thread completion");
            Thread.sleep(1000);
          }
       }
       catch(InterruptedException e)
       {
         System.out.println("Main thread interrupted");
       }
   }

   public void waitForExpected(String cmd, String expectedVal, String key)
   {
     waitForExpected("0", cmd, expectedVal, key, false);
   }

   public void waitForExpected(String testNum, String cmd, String expectedVal, String key, boolean keepRetrying)
   {
     String actualVal = "";
     int MAX_RETRIES = 60;
     int retry = 0;
     while (!actualVal.equals(expectedVal))
     {
       System.out.println("retry #" + retry + "; Waiting for expected " + key + " - " + expectedVal);
       Race race0 = new Race("t"+testNum, cmd, 0);
       race0.start();
       waitForThreadCompletion(race0);
       try
       {
         actualVal = getResourceAttr(race0.getSb(), key);
       } catch (ResourceUnavailableException e)
       {
         if (!keepRetrying)
         {
           throw e;
         }
       }
       retry++;
       if (retry == this.MAX_RETRIES)
       {
         throw new ResourceUnavailableException("Resource failed to attain " + key + " - " + expectedVal + " in " + this.MAX_RETRIES + " retries");
       }
     }
   }

   public String getResourceAttr(String s, String attrHolder)
   {
     try
     {
       String v[] = s.split("\"" + attrHolder + "\": \"");
       v = v[1].split("\"");
       System.out.println(attrHolder + " " + v[0]);
       return v[0];
     } catch (ArrayIndexOutOfBoundsException e)
     {
       throw new ResourceUnavailableException("Resource Attribute(" + attrHolder + ") not available in output");
     }
   }

   public Race createVolume(String testNum)
   {
     return createVolume(testNum, null);
   }

   public Race createVolume(String testNum, String size)
   {
     String cmd;
     if (size == null)
     {
       // size = null => createVolume invoked as part of test pair
       if (isUseSnapshotId())
       {
         // this would happen when snapshot wasn't created as part of setup 
         // as CreateVolume,UseSnapshotId is part of the test pair
         if (this.snapshotId == null)
         {
           createSnapshotAvailable();
         }
         cmd = this.createVolCmd + "--SnapshotId " + this.snapshotId;
       } else {
         cmd = this.createVolCmd + "--Size " + this.size;
       }
     } else {
       // size != null => createVolume invoked as part of setup
       cmd = this.createVolCmd + "--Size " + size;
     }
     Race race0 = new Race("t" + testNum, cmd, 0);
     race0.start();
     System.out.println("Waiting for createVolume response to get volumeId");
     waitForThreadCompletion(race0);
     this.volumeId = getResourceAttr(race0.getSb(), "volumeId");
     this.allVolumes.add(this.volumeId);
     return race0;
   }

   public Race createSnapshot(String testNum)
   {
     // this would happen when volume wasn't created as part of setup
     // as CreateVolume,UseSnapshotId is part of the test pair
     if (this.volumeId == null)
     {
       createVolumeAvailable();
     }
     String cmd = "jcs compute CreateSnapshot --VolumeId " + this.volumeId;
     Race race0 = new Race("t" + testNum, cmd, 0);
     race0.start();
     System.out.println("Waiting for createSnapshot response to get snapshotId");
     waitForThreadCompletion(race0);
     this.snapshotId = getResourceAttr(race0.getSb(), "snapshotId");
     this.allSnapshots.add(this.snapshotId);
     return race0;
   }

   public String createSnapshotAvailable()
   {
     createSnapshot("0");
     String cmd = "jcs compute DescribeSnapshots --SnapshotId " + this.snapshotId;
     waitForExpected(cmd, "completed", "status");
     return this.snapshotId;
   }

   public String createVolumeAvailable()
   {
     // createVolumeAvailable is part of setup and must always use size
     createVolume("0", this.size);
     String cmd = this.descVolCmd + this.volumeId;
     waitForExpected(cmd, "available", "status");
     return this.volumeId;
   }

   public Race attachVolume(String testNum)
   {
     return attachVolume(testNum, null);
   }

   public Race attachVolume(String testNum, String instanceId)
   {
     if (instanceId == null)
     {
       instanceId = this.instanceId;
     }
     String cmd = "jcs compute AttachVolume --InstanceId " + instanceId + " --VolumeId " + this.volumeId + " --Device /dev/vdb";
     Race race0 = new Race("t" + testNum, cmd, 0);
     race0.start();
     return race0;
   }

   public String attachVolumeAvailable()
   {
     attachVolume("0");
     String cmd = this.descVolCmd + this.volumeId;
     waitForExpected(cmd, "in-use", "status");
     return this.volumeId;
   }

   public Race detachVolume(String testNum)
   {
     return detachVolume(testNum, null);
   }

   public Race detachVolume(String testNum, String instanceId)
   {
     if (instanceId == null)
     {
       instanceId = this.instanceId;
     }
     String cmd = this.detachVolCmd + "--InstanceId " + instanceId + " --VolumeId " + this.volumeId;
     Race race0 = new Race("t" + testNum, cmd, 0);
     race0.start();
     return race0;
   }

   public Race deleteVolume(String testNum)
   {
     String cmd = this.deleteVolCmd + this.volumeId;
     Race race = new Race("t" + testNum, cmd, 100);
     race.start();
     return race;
   }

   public Race deleteSnapshot(String testNum)
   {
     String cmd = this.deleteSnapCmd + this.snapshotId;
     Race race = new Race("t" + testNum, cmd, 100);
     race.start();
     return race;
   }

   public String createInstanceAvailable()
   {
     String cmd = "jcs compute RunInstances --ImageId jmi-d523af5f --KeyName vivek_key --InstanceTypeId c1.medium --BlockDeviceMapping.1.DeleteOnTermination True --BlockDeviceMapping.1.DeviceName /dev/vda";
     Race race0 = new Race("t0", cmd, 0);
     race0.start();
     System.out.println("Waiting for createInstance response to get instanceId");
     waitForThreadCompletion(race0);
     this.instanceId = getResourceAttr(race0.getSb(), "instanceId");
     this.allInstances.add(this.instanceId);
     cmd = "jcs compute DescribeInstances --InstanceId.1 " + this.instanceId;
     waitForExpected(cmd, "running", "instanceState");
     return this.instanceId;
   }

   public Race runCmd(String op, String testNum)
   {
     Race race = null;
     switch (op) 
     {
       case "CreateVolume":
         race = createVolume(testNum);
         break;
       case "CreateSnapshot":
         race = createSnapshot(testNum);
         break;
       case "AttachVolume":
         race = attachVolume(testNum);
         break;
       case "DetachVolume":
         race = detachVolume(testNum);
         break;
       case "DeleteVolume":
         race = deleteVolume(testNum);
         break;
       case "DeleteSnapshot":
         race = deleteSnapshot(testNum);
         break;
     }
     return race;
   }

   public void cleanup()
   {
     String cmd;
     Race race0;
     String snapshotId = null;
     System.out.println("Attempt snap cleanup");
     for(int index=0; index < this.allSnapshots.size(); index++)
     {
       snapshotId = this.allSnapshots.get(index);
       cmd = this.deleteSnapCmd + snapshotId;
       // we could end up issuing a delete during a state-transitional phase
       // so lets keep retrying until MAX_RETRIES to delete.
       try
       {
         waitForExpected("n", cmd, "true", "return", true);
       } catch (ResourceUnavailableException e)
       {
         e.printStackTrace();  
         System.out.println("Unable to delete snap " + snapshotId + " after " + this.MAX_RETRIES + " attempts. Try manually");
       }
     }
     this.snapshotId = null;
     this.allSnapshots = new ArrayList<String>();
     String volumeId = null;
     String status = "";
     String code = "";
     String instanceId = null;
     for(int index=0; index < this.allVolumes.size(); index++)
     {
       volumeId = this.allVolumes.get(index);
       cmd = this.descVolCmd + volumeId;
       race0 = new Race("tn", cmd, 0);
       race0.start();
       System.out.println("Checking if the volume is attached, to detach");
       waitForThreadCompletion(race0);
       try
       {
         status = getResourceAttr(race0.getSb(), "status");
       } catch (ResourceUnavailableException e)
       {
         //"Code": "InvalidVolume.NotFound"
         code = getResourceAttr(race0.getSb(), "Code");
       }
       if (status.equals("in-use") || status.equals("attaching"))
       {
         System.out.println("Attempting to detach volume");
         instanceId = getResourceAttr(race0.getSb(), "instanceId");
         cmd = this.detachVolCmd + "--InstanceId " + instanceId + " --VolumeId " + volumeId;
         // we could end up issuing a detach during a state-transitional phase
         // so lets keep retrying until MAX_RETRIES to detach.
         try
         {
           waitForExpected("n", cmd, "detaching", "status", true);
         } catch (ResourceUnavailableException e)
         {
           e.printStackTrace();  
           System.out.println("Unable to detach vol " + volumeId + " after " + this.MAX_RETRIES + " attempts. Try manually");
         }
       }
       if (code.equals("InvalidVolume.NotFound"))
       {
         System.out.println("Volume already deleted; moving on...");
       } else 
       {
         cmd = this.deleteVolCmd + volumeId;
         System.out.println("Attempting to delete volume");
         // we could end up issuing a delete during a state-transitional phase
         // so lets keep retrying until MAX_RETRIES to delete.
         try
         {
           waitForExpected("n", cmd, "true", "return", true);
         } catch (ResourceUnavailableException e)
         {
           e.printStackTrace();  
           System.out.println("Unable to delete vol " + volumeId + " after " + this.MAX_RETRIES + " attempts. Try manually");
         }
       }
     }
     this.volumeId = null;
     this.allVolumes = new ArrayList<String>();
     for(int index=0; index < this.allInstances.size(); index++)
     {
       cmd = "jcs compute TerminateInstances --InstanceId.1 " + this.allInstances.get(index);
       race0 = new Race("tn", cmd, 0);
       race0.start();
       System.out.println("Waiting for inst cleanup thread to complete");
       waitForThreadCompletion(race0);
     }
     this.instanceId = null;
     this.allInstances = new ArrayList<String>();
   }
}

class RaceTestRunner
{
   public static void main(String args[])
   {
    try(BufferedReader br = new BufferedReader(new FileReader("racetestcases.txt"))) {
        StringBuilder sb = new StringBuilder();
        String volumeId = "";
        String cmd = "";
        Test test = new Test();
        // first line should contain the default size and test repetition count
        String line = br.readLine();
        String[] defs = line.split(",");
        test.setDefaultSize(defs[0].split("=")[1]);
        int count = Integer.parseInt(defs[1].split("=")[1]);
        line = br.readLine();
    
        while (line != null) {
            String[] cmds = line.split(",");
            System.out.println("Current Test " + cmds[0] + "," + cmds[1] + " all runs begin;");
            for (int i = 2; i < cmds.length; i++)
            {
              switch (cmds[i])
              {
                case "UseSnapshotId":
                  test.setUseSnapshotId();
                  break;
                case "UseAttachedVolume":
                  test.setUseAttachedVolume();
                  break;
                case "UseDifferentInstance":
                  test.setUseDifferentInstance();
                  break;
                default:
                  if (cmds[i].startsWith("UseSize="))
                  {
                    test.setTestLocalSize(cmds[i]);
                  } else
                  {
                    System.out.println("Invalid option: " + cmds[i]);
                  }
              }
            }
            for (int i = 0; i < count; i++) {
              try
              {
                String cv = "CreateVolume";
                String av = "AttachVolume";
                String dv = "DetachVolume";
                //String cs = "CreateSnapshot";
                String ds = "DeleteSnapshot";
                Race race1 = null;
                Race race2 = null;
                if (!cmds[0].equals(cv))
                {
                  // we need a volume to operate on
                  test.createVolumeAvailable();
                }
                if ((test.isUseSnapshotId() && (cmds[0].equals(ds) || cmds[1].equals(ds))) || (cmds[0].equals(ds) && cmds[1].equals(ds)))
                {
                  // DeleteSnapshot/CreateVolume from snapshot requires a snapshot
                  // DeleteSnapshot/DeleteSnapshot requires a snapshot
                  // so create a snapshot ourselves only if its either of those three cases
                  test.createSnapshotAvailable();
                }
                if (test.isUseAttachedVolume() || cmds[0].equals(av) || cmds[1].equals(av) || cmds[0].equals(dv) || cmds[1].equals(dv))
                {
                  // we need instance for attach/detach ops
                  test.createInstanceAvailable();
                }
                if (test.isUseAttachedVolume() || cmds[0].equals(dv) || (cmds[1].equals(dv) && !cmds[0].equals(av)))
                {
                  // eg. the pair could be DetachVolume/DeleteVolume so attached volume is a prerequisite;
                  // same with CreateSnapshot/DetachVolume
                  test.attachVolumeAvailable();
                }
                if (test.isUseDifferentInstance())
                {
                  // special case handle operations on two different instances
                  // create the second instance
                  test.createInstanceAvailable();
                  List<String> instances = test.getAllInstances();
                  for (int j = 0; j <= 1; i++)
                  {
                    switch (cmds[j])
                    {
                      case "AttachVolume": race1 = test.attachVolume(Integer.toString(j+1), instances.get(j));
                                           break;
                      case "DetachVolume": race2 = test.detachVolume(Integer.toString(j+1), instances.get(j));
                                           break;
                    }
                  }
                } else
                {
                  // ..start the two commands in the given order
                  race1 = test.runCmd(cmds[0], "1");
                  race2 = test.runCmd(cmds[1], "2");
                }
                test.waitForThreadCompletion(race1);
                test.waitForThreadCompletion(race2);
              } catch(ResourceUnavailableException e) {
                e.printStackTrace();
                System.out.println(e.getMessage());
              }
              test.cleanup();
              System.out.println("Current Test run #" + (i+1) + " complete; Moving to nexti run, if any");
            }
            System.out.println("Current Test " + cmds[0] + "," + cmds[1] + " all runs complete; Moving to next test, if any");
            // reset to defaults
            test.resetOpts();
            line = br.readLine();
        }
    } catch (Exception e) {
             e.printStackTrace();  
             System.out.println("UNEXPECTED.ERROR.RUNNING.TESTSUITE");  
    }

   }
}


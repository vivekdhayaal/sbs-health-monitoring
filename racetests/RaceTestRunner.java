import java.io.BufferedReader;
import java.io.FileReader;
import java.io.InputStreamReader;
class Race extends Thread
{
   private String cmd;
   private int st;
   private StringBuilder sb = new StringBuilder();
   Race(String n, String v, int t)
   {
     super(n);
     this.cmd = v;
     this.st = t;
     //start();
   }
   public void run()
   {
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
            System.out.println(this.sb);
        } catch (Exception e) {
             e.printStackTrace();  
             System.out.println(this.getName() + "ERROR.RUNNING.CMD");  
        }
   }

   public String getSb() {
     return this.sb.toString();
   }
}

class Test
{
   private String instanceId = null;
   private String volumeId = null;
   private String snapshotId = null;
   private String size;

   public String setSize(String size)
   {
    this.size = size;
    return this.size;
   }

   public String getSize()
   {
    return this.size;
   }

   public String readTestLocalSize(String size, String specsStr)
   {
     //String size;
     String[] specs = specsStr.split("=");
     if (specs[0].equals("UseSize"))
     {
       size = specs[1];
     } else if (specs[0].equals("UseSnapshotId")) {
       // we shold create volume from snapshot
       size = null;
     }
     return size;
   }

   public void waitForResourceAvailability(String cmd, String expected, String statusHolder)
   {
     String status = "";
     //String expected = "available";
     while (!status.equals(expected))
     {
       Race race0 = new Race("t0", cmd, 0);
       race0.start();
       try
       {
          while(race0.isAlive())
          {
            System.out.println("Waiting for resource to become available");
            Thread.sleep(1000);
          }
       }
       catch(InterruptedException e)
       {
         System.out.println("Main thread interrupted");
       }
       String s = race0.getSb();
       String[] v = s.split("\"" + statusHolder + "\": \"");
       v = v[1].split("\"");
       System.out.println("status " + v[0]);
       status = v[0];
     }
   }

   public void waitForResourceAvailability(String cmd, String expected)
   {
     waitForResourceAvailability(cmd, expected, "status");
   }

   public Race createVolume(String param)
   {
     String cmd;
     if (!(param == null))
     {
       cmd = "jcs compute CreateVolume --Size " + param;
     } else {
       cmd = "jcs compute CreateVolume --SnapshotId " + createSnapshot();
     }
     Race race0 = new Race("t0", cmd, 0);
     race0.start();
     try
     {
        while(race0.isAlive())
        {
          System.out.println("Waiting for createVolume response to get volumeId");
          Thread.sleep(1000);
        }
     }
     catch(InterruptedException e)
     {
       System.out.println("Main thread interrupted");
     }
     String s = race0.getSb();
     String v[] = s.split("\"volumeId\": \"");
     v = v[1].split("\"");
     System.out.println("volumeId " + v[0]);
     this.volumeId = v[0];
     return race0;
   }

   public String createSnapshot()
   {
     String cmd = "jcs compute CreateSnapshot --VolumeId " + createVolumeAvailable(this.size);
     Race race0 = new Race("t0", cmd, 0);
     race0.start();
     try
     {
        while(race0.isAlive())
        {
          System.out.println("Waiting for createSnapshot response to get snapshotId");
          Thread.sleep(1000);
        }
     }
     catch(InterruptedException e)
     {
       System.out.println("Main thread interrupted");
     }
     String s = race0.getSb();
     String v[] = s.split("\"snapshotId\": \"");
     v = v[1].split("\"");
     System.out.println("snapshotId " + v[0]);
     this.snapshotId = v[0];
     cmd = "jcs compute DescribeSnapshots --SnapshotId " + this.snapshotId;
     waitForResourceAvailability(cmd, "completed");
     return this.snapshotId;
   }

   public String createVolumeAvailable(String size)
   {
     createVolume(size);
     String cmd = "jcs compute DescribeVolumes --VolumeId " + this.volumeId;
     waitForResourceAvailability(cmd, "available");
     return this.volumeId;
   }

   public Race attachVolume()
   {
     String cmd = "jcs compute AttachVolume --InstanceId " + this.instanceId + " --VolumeId " + this.volumeId + " --Device /dev/vdb";
     System.out.println("vivek=======================" + cmd);
     Race race0 = new Race("t0", cmd, 0);
     race0.start();
     return race0;
   }

   public String attachVolumeAvailable()
   {
     attachVolume();
     String cmd = "jcs compute DescribeVolumes --VolumeId " + this.volumeId;
     waitForResourceAvailability(cmd, "in-use");
     return this.volumeId;
   }

   public Race detachVolume()
   {
     String cmd = "jcs compute DetachVolume --InstanceId " + this.instanceId + " --VolumeId " + this.volumeId;
     Race race0 = new Race("t0", cmd, 0);
     race0.start();
     return race0;
   }

   public String createInstance()
   {
     String cmd = "jcs compute RunInstances --ImageId jmi-d523af5f --KeyName vivek_key --InstanceTypeId c1.medium --BlockDeviceMapping.1.DeleteOnTermination True --BlockDeviceMapping.1.DeviceName /dev/vda";
     Race race0 = new Race("t0", cmd, 0);
     race0.start();
     try
     {
        while(race0.isAlive())
        {
          System.out.println("Waiting for createInstance response to get instanceId");
          Thread.sleep(1000);
        }
     }
     catch(InterruptedException e)
     {
       System.out.println("Main thread interrupted");
     }
     String s = race0.getSb();
     String v[] = s.split("\"instanceId\": \"");
     v = v[1].split("\"");
     System.out.println("instanceId " + v[0]);
     this.instanceId = v[0];
     cmd = "jcs compute DescribeInstances --InstanceId.1 " + this.instanceId;
     waitForResourceAvailability(cmd, "running", "instanceState");
     return this.instanceId;
   }

   public Race runCmd(String op, String testNum)
   {
     String av = "AttachVolume";
     String dv = "DetachVolume";
     Race race = null;
     if (op.equals(av))
     {
       race = attachVolume();
     } else if (op.equals(dv))
     {
       race = detachVolume();
     } else 
     {
       String cmd = "jcs compute " + op + " --VolumeId " + this.volumeId;
       race = new Race("t" + testNum, cmd, 100);
       race.start();
     }
     return race;
   }

   public void cleanup()
   {
     String cmd = "jcs compute DeleteVolume --VolumeId " + this.volumeId;
     Race race0 = new Race("tn", cmd, 0);
     race0.start();
     try
     {
        while(race0.isAlive())
        {
          System.out.println("Waiting for vol cleanup thread to complete");
          Thread.sleep(1000);
        }
     }
     catch(InterruptedException e)
     {
       System.out.println("Main thread interrupted");
     }
     this.volumeId = null;
     if (!(this.snapshotId == null))
     {
       cmd = "jcs compute DeleteSnapshot --SnapshotId " + this.snapshotId;
       race0 = new Race("tn", cmd, 0);
       race0.start();
       try
       {
          while(race0.isAlive())
          {
            System.out.println("Waiting for snap cleanup thread to complete");
            Thread.sleep(1000);
          }
       }
       catch(InterruptedException e)
       {
         System.out.println("Main thread interrupted");
       }
       this.snapshotId = null;
     }
     if (!(this.instanceId == null))
     {
       cmd = "jcs compute TerminateInstances --InstanceId.1 " + this.instanceId;
       race0 = new Race("tn", cmd, 0);
       race0.start();
       try
       {
          while(race0.isAlive())
          {
            System.out.println("Waiting for inst cleanup thread to complete");
            Thread.sleep(1000);
          }
       }
       catch(InterruptedException e)
       {
         System.out.println("Main thread interrupted");
       }
       this.instanceId = null;
     }
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
        String size = test.setSize(defs[0].split("=")[1]);
        int count = Integer.parseInt(defs[1].split("=")[1]);
        line = br.readLine();
    
        while (line != null) {
            String[] cmds = line.split(",");
            System.out.println("cmds[o] " + cmds[0]);
            System.out.println("cmds[1] " + cmds[1]);
            if (cmds.length > 2)
            {
              size = test.readTestLocalSize(size, cmds[2]);
            }
            for (int i = 0; i < count; i++) {
              String cv = "CreateVolume";
              String av = "AttachVolume";
              String dv = "DetachVolume";
              Race race1 = null;
              Race race2 = null;
              if (cmds[0].equals(av) || cmds[1].equals(av) || cmds[0].equals(dv) || cmds[1].equals(dv))
              {
                // we need insgtance for attach/detach ops
                test.createInstance();
              }
              if (cmds[0].equals(cv))
              {
                String nextCmd = cmds[1];
                // we need the volume created to run the next command
                race1 = test.createVolume(size);
                race2 = test.runCmd(nextCmd, "2");
              } else if (cmds[1].equals(cv))
              {
                String nextCmd = cmds[0];
                // we need the volume created to run the next command
                race1 = test.createVolume(size);
                race2 = test.runCmd(nextCmd, "2");
              } else {
                // create the resource ourselves and...
                test.createVolumeAvailable(size);
                if ((cmds[0].equals(dv) || cmds[1].equals(dv)) && (!(cmds[0].equals(av)) || !(cmds[1].equals(dv))))
                {
                  // the pair should be DetachVolume/DeleteVolume so attached volume is a prerequisite
                  test.attachVolumeAvailable();
                }
                // ..start the two commands in the given order
                race1 = test.runCmd(cmds[0], "1");
                race2 = test.runCmd(cmds[1], "2");
              }
              try
              {
                 while(race1.isAlive() || race2.isAlive())
                 {
                   //System.out.println("Main thread will be alive till the child thread is live");
                   Thread.sleep(1500);
                 }
              }
              catch(InterruptedException e)
              {
                System.out.println("Main thread interrupted");
              }
              test.cleanup();
              // reset size to default size
              size = test.getSize();
              System.out.println("Current Test run #" + (i+1) + " complete; Moving to nexti run, if any");
            }
            System.out.println("Current Test all runs complete; Moving to next test, if any");
            line = br.readLine();
        }
    } catch (Exception e) {
             e.printStackTrace();  
             System.out.println("ERROR.RUNNING.CMD");  
    }

   }
}


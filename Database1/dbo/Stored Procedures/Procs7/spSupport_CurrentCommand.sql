CREATE PROCEDURE dbo.spSupport_CurrentCommand
AS
Select SPId = SPId ,
       Cmd = Cmd,
       AppName = Substring(Program_Name, 1,12),
       Status = Status,
       Login = Substring(LogiName,1,12),
       Hostname = Substring(Hostname,1,15),
       Blocked = Convert(char(5),Blocked),
       DBName = Substring(DB_Name(DBId),1,10),
       AppName = Program_Name,
       Cmd = Cmd
  From Master.DBO.SysProcesses
  Where Cmd not in ('AWAITING COMMAND', 'SIGNAL HANDLER', 'LOCK MONITOR', 'LAZY WRITER', 'LOG WRITER', 'CHECKPOINT SLEEP') 
  Order By Blocked Desc, SPID
--  Order By DBName,Login,Status,Hostname

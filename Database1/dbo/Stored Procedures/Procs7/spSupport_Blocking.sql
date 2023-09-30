CREATE PROCEDURE dbo.spSupport_Blocking
AS
Print 'Blocking SPids:' 
Select SPId = SPId ,
       Status = Status,
       Login = Substring(LogiName,1,12),
       Hostname = Substring(Hostname,1,15),
       Blocked = Convert(char(5),Blocked),
       DBName = Substring(DB_Name(DBId),1,10),
       AppName = Program_Name,
       Cmd = Cmd
  From Master.DBO.SysProcesses
  Where Blocked <> SPId
  Order By Blocked Desc, SPID
Create Table #Blocked(Spid int)
Insert into #Blocked 
Select Blocked
From Master.DBO.SysProcesses  Where Blocked <> 0 and Blocked <> SPId
Print 'Locks for blocking SPids:' 
select distinct so.name, AppName = Program_Name, Cmd = Cmd
from master..syslockinfo sl
Join #Blocked bb On sl.req_spid = bb.Spid
Join sys.sysobjects so on so.id = sl.rsc_objid
Join Master.DBO.SysProcesses p on sl.req_spid = p.spid
where  sl.rsc_objid <> 0
Drop table #Blocked

CREATE PROCEDURE dbo.spSupport_CurrentActivity
AS
Set NoCount On
Select CurrentTime = GetDate(), @@SPID as 'This SPID'
Print ''
Print ''
Declare
  @DBName       varchar(50),
  @CommandStr1  Varchar(255),
  @CommandStr2  Varchar(255),
  @CommandStr3  Varchar(255),
  @CommandStr4  Varchar(255),
  @CommandStr5  Varchar(255),
  @CommandStr6  Varchar(255),
  @CommandStr7  Varchar(255),
  @CommandStr8  Varchar(255),
  @CommandStr9  Varchar(255)
Select @DBName = DB_Name()
Select @CommandStr1 = ' Select SPID = sl.SPId, DBName = Substring(DB_Name(sl.DBId), 1, 15) ,'
Select @CommandStr2 = ' Locktype = v.Name, '
Select @CommandStr3 = ' Table_Desc = Case DB_Name(sl.DBId) '
Select @CommandStr4 = ' When ' + Char(39) + 'Master' + Char(39) + ' Then (Select Name From Master.DBO.SysObjects Where Id = sl.Id) '
Select @CommandStr5 = ' When ' + Char(39) + 'TempDB' + Char(39) + ' Then (Select Name From TempDB.DBO.SysObjects Where Id = sl.Id) '
Select @CommandStr6 = ' When ' + Char(39) + @DBName  + Char(39) + ' Then (Select Name From ' + @DBName + '.DBO.SysObjects Where Id = sl.Id)'
Select @CommandStr7 = ' Else ' + Char(39) + 'Unknown-DB' + Char(39) + ' End '
Select @CommandStr8 = ' From Master.DBO.SysLocks sl, Master.DBO.Spt_Values v Where (sl.Type = v.Number) And '
Select @CommandStr9 = ' (v.Type = ' + Char(39) + 'L' + Char(39) + ') Order By DBName, Table_Desc, SPId, Locktype'
Execute (@CommandStr1 + @CommandStr2 + @CommandStr3 + @CommandStr4 + @CommandStr5 + @CommandStr6 + @CommandStr7 + @CommandStr8 + @CommandStr9)
/*
Select SPID = sl.SPId,DBName = Substring(DB_Name(sl.DBId), 1, 15),
       Locktype = v.Name,
       Table_Desc = 
 	  Case Substring(DB_Name(sl.DBId), 1, 15)
 	    When 'Master' Then (Select Name From Master.DBO.SysObjects Where Id = sl.Id)
 	    When 'TempDB' Then (Select Name From TempDB.DBO.SysObjects Where Id = sl.Id)
 	    When 'GBDB' Then (Select Name From GBDB.DBO.SysObjects Where Id = sl.Id)
 	    Else 'Unknown-DB'
 	  End
  From Master.DBO.SysLocks sl, 
       Master.DBO.Spt_Values v
  Where (sl.Type = v.Number) And
        (v.Type = 'L')
  Order By DBName, Table_Desc, SPId, Locktype
*/
Print ''
Print ''
Select SPId = SPId ,
       Status = Status,
       Login = Substring(LogiName,1,12),
       Hostname = Substring(Hostname,1,15),
       Blocked = Convert(char(5),Blocked),
       DBName = Substring(DB_Name(DBId),1,10),
       AppName = Program_Name,
       Cmd = Cmd
  From Master.DBO.SysProcesses
  Order By Blocked Desc, SPID
--  Order By DBName,Login,Status,Hostname
Set NoCount Off

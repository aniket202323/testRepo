CREATE PROCEDURE dbo.spServer_CmnGetHistorians
AS
Declare
  @@HistId int,
  @@HistTypeId int,
  @Tmp nVarChar(500),
  @@HistOptionId int,
  @@HistOptionValue nVarChar(255)
Declare @DataSources Table(HistId int, HistType int, Alias nVarChar(255) COLLATE DATABASE_DEFAULT NULL, Servername nVarChar(255) COLLATE DATABASE_DEFAULT, Username nvarchar(50) COLLATE DATABASE_DEFAULT NULL, IsDefault int NULL, OSId int, HistTypeId int, IsRemote int NULL, DllName nVarChar(255) COLLATE DATABASE_DEFAULT NULL, RemoteDllName nVarChar(255) COLLATE DATABASE_DEFAULT NULL)
Insert Into @DataSources(HistId,HistType,Alias,Servername,Username,IsDefault,OSId,HistTypeId,IsRemote)
(Select Hist_Id,Hist_Type_Id,Alias,Hist_Servername,Hist_Username,Hist_Default,Hist_OS_Id,Hist_Type_Id,Is_Remote From Historians Where (Is_Active = 1))
Update @DataSources Set DllName = 'PR2RDS.dll' Where IsRemote = 1
Update @DataSources Set Alias = Servername Where Alias Is NULL
Update @DataSources
  Set DllName = t.Hist_Type_DllName
  From @DataSources d, Historian_Types t
  Where (d.HistTypeId = t.Hist_Type_Id) And ((d.IsRemote Is NULL) Or (d.IsRemote = 0))
Update @DataSources
  Set RemoteDllName = t.Hist_Type_DllName
  From @DataSources d, Historian_Types t
  Where (d.HistTypeId = t.Hist_Type_Id) And (d.IsRemote = 1)
Update @DataSources Set DllName = (Select Hist_Type_DllName From Historian_Types Where Hist_Type_Id = 3) Where ((IsRemote Is NULL) Or (IsRemote = 0)) And (HistTypeId = 2)
Update @DataSources Set RemoteDllName = (Select Hist_Type_DllName From Historian_Types Where Hist_Type_Id = 3) Where (IsRemote = 1) And (HistTypeId = 2)
-- Decrypt Historian Passwords
Create Table #HistorianPW(Hist_Id Int,  Hist_Password  nvarchar(255))
Execute spCmn_GetHistorianPWData2 'EncrYptoR'
Select   s.ServerName,
         s.Username,
         p.Hist_Password,
         s.IsDefault,
         s.OSId,
         s.DllName,
         s.Alias,
         s.RemoteDllName,
         s.HistId,
         s.HistType
From     @DataSources s join #HistorianPW p on s.HistId = p.Hist_Id
Where    (DllName Is Not NULL)
Order By ServerName
select    d.HistId,
          o.Hist_Option_Id,
          o.Value
 From     @DataSources d, Historian_Option_Data o
 Where    d.HistId = o.Hist_Id
 Order By d.HistId, o.Hist_Option_Id
drop table #HistorianPW

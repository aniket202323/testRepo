CREATE PROCEDURE dbo.spEM_GetDiagSps 
  AS
  Create Table #SpNames(Name nvarchar(50),DisplayName nvarchar(50),TabName nvarchar(25),TabOrder int,NameIndex Int,UseParameters Int)
  Insert Into #SpNames (Name,DisplayName,TabName,TabOrder,NameIndex,UseParameters) Values ('spSupport_ReaderVarFreq','Reader Sampling Interval','ReaderSamplingInterval',1,1,0)
  Insert Into #SpNames (Name,DisplayName,TabName,TabOrder,NameIndex,UseParameters) Values ('spSupport_Blocking','Blocking','Blocking',1,2,0)
  Insert Into #SpNames (Name,DisplayName,TabName,TabOrder,NameIndex,UseParameters) Values ('spSupport_Blocking','Blocking','Tables',2,2,0)
  Insert Into #SpNames (Name,DisplayName,TabName,TabOrder,NameIndex,UseParameters) Values ('spEM_ShowSPStats','Stored Procedures','Totals',1,3,0)
  Insert Into #SpNames (Name,DisplayName,TabName,TabOrder,NameIndex,UseParameters) Values ('spEM_ShowSPStats','Stored Procedures','Services',2,3,0)
  Insert Into #SpNames (Name,DisplayName,TabName,TabOrder,NameIndex,UseParameters) Values ('spEM_ShowSPStats','Stored Procedures','% of Services Time',3,3,0)
  Insert Into #SpNames (Name,DisplayName,TabName,TabOrder,NameIndex,UseParameters) Values ('spEM_ShowEventModelStats','Model Statistics','Totals',1,4,0)
  Insert Into #SpNames (Name,DisplayName,TabName,TabOrder,NameIndex,UseParameters) Values ('spEM_ShowEventModelStats','Model Statistics','Statistics',2,4,0)
  Insert Into #SpNames (Name,DisplayName,TabName,TabOrder,NameIndex,UseParameters) Values ('spEM_ShowMsgProcStats','Message Statistics','Messages',1,5,0)
  Insert Into #SpNames (Name,DisplayName,TabName,TabOrder,NameIndex,UseParameters) Values ('spEM_ShowProcessStats','CPU Statistics','Total CPU',1,6,0)
  Insert Into #SpNames (Name,DisplayName,TabName,TabOrder,NameIndex,UseParameters) Values ('spEM_ShowProcessStats','CPU Statistics','CPU By Service',2,6,0)
  Select Name,DisplayName,TabName,TabOrder,NameIndex,UseParameters from #SpNames Order by DisplayName,TabOrder
  Select Service_Desc from cxs_service Where Is_Active = 1 Order By Service_Desc
  Drop table #SpNames

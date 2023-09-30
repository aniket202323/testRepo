Create Procedure dbo.[spSDK_Hist_GetAvailableConnections60_Bak_177]
AS
declare @HistDesc Table(Hist_Id Int,  Alias  VarChar(255),  Hist_Type_Id Int, Hist_Type_Desc  VarChar(255), HistServer VarChar(255), ProgId VarChar(255), Hist_Desc  VarChar(255))
insert @HistDesc (Hist_Id, Alias, Hist_Type_Id, Hist_Type_Desc, HistServer, ProgId)
select h.Hist_Id, h.Alias, h.Hist_Type_Id, t.Hist_Type_Desc, h.Hist_Servername, d.Value
 	 from Historians h
 	 join Historian_Types t on t.Hist_Type_Id = h.Hist_Type_Id
  left outer join Historian_Option_Data d on d.Hist_Id = h.Hist_Id and d.Hist_Option_Id = 3 
update @HistDesc set Hist_Desc = Hist_Type_Desc + ' on ' + HistServer
update @HistDesc set Hist_Desc = Hist_Type_Desc + ' (' + ProgId + ') on ' + HistServer where Hist_Id in (select Hist_Id from Historians where Hist_Type_Id = 5)
Select Alias, Hist_Desc from @HistDesc

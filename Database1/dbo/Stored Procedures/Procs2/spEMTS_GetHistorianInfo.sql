Create Procedure dbo.spEMTS_GetHistorianInfo 
 	 @PHNName nVarChar(20) = Null
AS
Declare @ServerName nvarchar(100)
  Create Table #HistorianPW(Hist_Id Int,  Hist_Password  nVarChar(255))
  Execute spCmn_GetHistorianPWData2  'EncrYptoR'
select @ServerName = Node_Name From Cxs_Service where Service_Id = 9
if @PHNName is null 
    BEGIN
 	 SELECT 	 hod.value,hod.Hist_Option_Id,PHN_Id = h.Hist_Id, PHN_Name = COALESCE(Hist_Servername,''), PHN_Username = COALESCE(Hist_Username,''),
 	  	  PHN_Password = COALESCE(hp.Hist_Password,''), PHN_Default = COALESCE(Hist_Default,''), PHN_OS = Hist_OS_Id, h.Hist_Type_Id, 
 	  	  Hist_Type_DllName = COALESCE(Hist_Type_DllName, ''), Hist_Servername = COALESCE(Hist_Servername, ''), Is_Remote, 
 	  	  Alias = COALESCE(Alias, Hist_Servername),Hist_RDS_Servername = case when Is_Remote = 0 then @ServerName else COALESCE(Hist_Servername, '') end
 	 FROM 	 historians h
 	  	 Join #HistorianPW hp on hp.Hist_Id = h.Hist_Id
        JOIN HISTORIAN_TYPES t on t.Hist_Type_Id = h.Hist_Type_Id
 	  	 Left Join  historian_Option_Data hod on hod.Hist_Id = h.Hist_Id
 	  	 Where is_Active = 1
 	 Order by h.Hist_Id,hod.Hist_Option_Id
    END
Else
    BEGIN
 	 SELECT 	 hod.value,hod.Hist_Option_Id,PHN_Id = h.Hist_Id, PHN_Name = COALESCE(Hist_Servername,''), PHN_Username = COALESCE(Hist_Username,''), 
 	  	  	  	 PHN_Password = COALESCE(hp.Hist_Password,''), PHN_Default = COALESCE(Hist_Default,''), PHN_OS = Hist_OS_Id, h.Hist_Type_Id, 
 	  	  	  	 Hist_Type_DllName = COALESCE(Hist_Type_DllName, ''), Hist_Servername = COALESCE(Hist_Servername, ''), Is_Remote, 
 	  	  	  	 Alias = COALESCE(Alias, Hist_Servername),Hist_RDS_Servername = case when Is_Remote = 0 then @ServerName else COALESCE(Hist_Servername, '') end
 	 FROM 	 historians h
  	    Join #HistorianPW hp on hp.Hist_Id = h.Hist_Id
       JOIN HISTORIAN_TYPES t on t.Hist_Type_Id = h.Hist_Type_Id
 	  	 Left Join  historian_Option_Data hod on hod.Hist_Id = h.Hist_Id
 	 WHERE 	 Hist_Servername = @PHNName
 	 Order by h.Hist_Id,hod.Hist_Option_Id
    END
Drop table #HistorianPW

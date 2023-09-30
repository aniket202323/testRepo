Create Procedure dbo.spPC_UpdateSiteDebug
  AS
 	 Update Site_Parameters Set Value = 0 Where  parm_Id = 112

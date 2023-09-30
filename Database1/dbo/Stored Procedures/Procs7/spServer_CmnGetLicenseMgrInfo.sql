CREATE PROCEDURE dbo.spServer_CmnGetLicenseMgrInfo
@LMNode nvarchar(200) OUTPUT,
@LMPort int OUTPUT,
@DBUsername nvarchar(200) OUTPUT
 AS
Select  @LMNode     = License_Mgr_Node,
        @LMPort     = License_Mgr_Port,
        @DBUsername = Database_Username
  from  License_Mgr_Info
  where Record_ID = 1

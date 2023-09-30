CREATE PROCEDURE [dbo].[spRS_GetReportOwnerInfo]
@Report_Id INT
 AS
DECLARE @USER_ID Int,@TimeZone VarChar(200)
SELECT  @TimeZone = coalesce(a.value,b.Default_Value) 
from Report_Definition_Parameters a
JOIN Report_Type_Parameters b on b.rtp_id = a.RTP_Id
where report_id = @Report_Id and b.RP_Id = -47
Select @User_Id = OwnerId From Report_Definitions Where Report_Id = @Report_Id
If @User_Id Is Null
  Select @User_id = 1
IF @TimeZone  IS NULL SELECT @TimeZone = ''
Select User_Id, User_Desc, UserName, Password,TimeZone =  @TimeZone
From users 
Where User_Id = @User_Id

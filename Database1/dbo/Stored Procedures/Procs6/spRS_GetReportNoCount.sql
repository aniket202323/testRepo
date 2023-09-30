/*
This Stored Procedure Determines If Local or Global Descriptions Should Be Used
Source:
ReportId -> OwnerId -> User_Parameters(LanguageId) = Site_Parameters(LanguageId)
Example:
spRS_GetReportNoCount 35021
spRS_GetReportNoCount 35024
set nocount on  -- Gives Local  (German in my case)
set nocount off -- Gives Global (English in my case)
select var_desc from variables
*/
CREATE PROCEDURE [dbo].[spRS_GetReportNoCount]
@Report_Id int
 AS
  DECLARE @SiteLanguageId Int
  DECLARE @OwnerId Int
  DECLARE @OwnerLanguageId Int
  DECLARE @SetNoCount VarChar(20)
  -----------------------------
  -- Get The Site Language Id
  -----------------------------
  Select @SiteLanguageId = Value From Site_Parameters Where Parm_Id = 8
  If @SiteLanguageId Is Null 
    Select @SiteLanguageId = 0
  -----------------------------
  -- Get The Report Owner's Id
  -----------------------------
  Select @OwnerId = OwnerId From Report_Definitions Where Report_Id = @Report_Id
  If @OwnerId Is Null
    Select @OwnerId = 1 -- ComXClient
  -----------------------------
  -- Get LangID of Report Owner
  -----------------------------
  Select @OwnerLanguageId = Convert(int, value) from User_Parameters where user_Id = @OwnerId and Parm_Id = 8
  If @OwnerLanguageId Is Null
    Select @OwnerLanguageId = 0
  If (@OwnerLanguageId = @SiteLanguageId) 
    Begin
 	 -- If Languages Are The Same Then Give The Local Descriptions 
        Select @SetNoCount = 'Set NoCount On'
    End
  Else
    Begin
 	 -- If Languages Are NOT The Same Then Give Global Descriptions
        Select @SetNoCount = 'Set NoCount Off' 
    End
  Select @SetNoCount 'SetNoCount'

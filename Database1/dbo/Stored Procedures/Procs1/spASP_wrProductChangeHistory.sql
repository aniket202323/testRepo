CREATE PROCEDURE [dbo].[spASP_wrProductChangeHistory]
 	 @EventId int,
 	 @InTimeZone nvarchar(200)=NULL
AS
-- Look up the language Id
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
/********************************
 	 Prompts
*********************************/
Declare @StartTime DateTime
Declare @EndTime DateTime
Select @StartTime = dbo.fnServer_CmnGetDate(getutcdate())
Select @EndTime = dbo.fnServer_CmnGetDate(getutcdate())
Declare @Prompts Table (PromptId int identity(1,1), PromptName nvarchar(255), PromptValue nvarchar(255), PromptValue_Parameter SQL_Variant, PromptValue_Parameter2 SQL_Variant, PromptValue_Parameter3 SQL_Variant)
Declare @ReportName nvarchar(255)
Declare @CriteriaString nvarchar(255)
Select @ReportName = dbo.fnTranslate(@LangId, -12345, 'Product Change History')
Insert into @Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Set @CriteriaString = dbo.fnTranslate(@LangId, 34647, 'For {0} From [{1}] To [{2}]')
IF @EndTime IS NULL
  Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2, PromptValue_Parameter3)
    Values ('Criteria', @CriteriaString, 'test', @StartTime, dbo.fnTranslate(@LangId, 34616, 'OPEN'))
ELSE
  Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2, PromptValue_Parameter3)
    Values('Criteria', @CriteriaString, 'test', @StartTime, @EndTime)
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter)
  Values('GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'), dbo.fnServer_CmnGetDate(getutcdate()))
Insert into @Prompts (PromptName, PromptValue) Values('History', dbo.fnTranslate(@LangId, 34648, 'History'))
Insert into @Prompts (PromptName, PromptValue) Values('Updated', dbo.fnTranslate(@LangId, 34649, 'Updated'))
Insert into @Prompts (PromptName, PromptValue) Values('Added', dbo.fnTranslate(@LangId, 34650, 'Added'))
Insert into @Prompts (PromptName, PromptValue) Values('Removed', dbo.fnTranslate(@LangId, 34651, 'Removed'))
Insert into @Prompts (PromptName, PromptValue) Values('FromValue', dbo.fnTranslate(@LangId, 34652, 'From Value'))
Insert into @Prompts (PromptName, PromptValue) Values('ToValue', dbo.fnTranslate(@LangId, 34653, 'To Value'))
Insert into @Prompts (PromptName, PromptValue) Values('UpdateTime', dbo.fnTranslate(@LangId, 34654, 'Update Time'))
Insert into @Prompts (PromptName, PromptValue) Values('UpdateUser', dbo.fnTranslate(@LangId, 34655, 'Update User'))
Insert into @Prompts (PromptName, PromptValue) Values('Start_Time', dbo.fnTranslate(@LangId, 34011, 'Start Time'))
Insert into @Prompts (PromptName, PromptValue) Values('End_Time', dbo.fnTranslate(@LangId, 34012, 'End Time'))
Insert into @Prompts (PromptName, PromptValue) Values('Duration', dbo.fnTranslate(@LangId, 34656, 'Duration'))
Insert into @Prompts (PromptName, PromptValue) Values('Comment_Text', dbo.fnTranslate(@LangId, -12345, 'Comment'))
Insert into @Prompts (PromptName, PromptValue) Values('PU_Desc', dbo.fnTranslate(@LangId, -12345, 'Unit'))
Insert into @Prompts (PromptName, PromptValue) Values('Event_Subtype_Id', dbo.fnTranslate(@LangId, -12345, 'Event Subtype'))
Insert into @Prompts (PromptName, PromptValue) Values('Confirmed', dbo.fnTranslate(@LangId, -12345, 'Confirmed'))
Insert into @Prompts (PromptName, PromptValue) Values('Confirmed', dbo.fnTranslate(@LangId, -12345, 'Confirmed'))
Select PromptId, PromptName, PromptValue , 'PromptValue_Parameter'= case when (ISDATE(Convert(varchar,PromptValue_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end ,
 'PromptValue_Parameter2'= case when (ISDATE(Convert(varchar,PromptValue_Parameter2))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter2),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter2
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end ,
  'PromptValue_Parameter3'= case when (ISDATE(Convert(varchar,PromptValue_Parameter3))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter3),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter3
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end 
from @Prompts
/********************************
 	 Data retrieval
*********************************/
Select psh.Modified_On, u.Username, Confirmed, 'Start_Time'=   [dbo].[fnServer_CmnConvertFromDbTime] (Start_Time,@InTimeZone) , 'End_Time'=   [dbo].[fnServer_CmnConvertFromDbTime] (End_Time,@InTimeZone) , Event_Subtype_Id, PU.PU_Desc,
 	 c.Comment_Text
From Production_Starts_History psh
Left outer Join Users u on u.user_id = psh.user_id
Left Outer Join Prod_Units pu On pu.PU_Id = psh.PU_Id
Left Outer Join Products prods On psh.Prod_Id = prods.Prod_Id
left outer join Comments c On psh.Comment_Id = c.Comment_Id
Where Start_Id = @EventId
Order By psh.Modified_On ASC

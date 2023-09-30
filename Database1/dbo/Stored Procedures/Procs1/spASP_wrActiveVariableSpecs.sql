/*
spASP_wrActiveVariableSpecs null
*/
CREATE procedure [dbo].[spASP_wrActiveVariableSpecs]
@ReportId int = Null,
@RunId int = NULL
AS
Declare @Now DateTime
Declare @LocaleId int,@LangId int,@ReturnValue int
SELECT 	 @ReturnValue = NULL
EXEC 	 spRS_GetReportParamValue 'LocaleId', @ReportId, @ReturnValue output
SELECT 	 @LocaleId = CASE @ReturnValue WHEN NULL THEN 0 ELSE abs(convert(INT, @ReturnValue)) END
SELECT @LangId = Language_id From Language_Locale_Conversion Where LocaleId=@LocaleId
If @LangId is Null SET @LangId = 0
--**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
declare @TargetTimeZone varchar(200)--Sarla
Select @TargetTimeZone = NULL--Sarla
EXEC spRS_GetReportParamValue 'TargetTimeZone', @ReportId, @TargetTimeZone output
Create Table #Prompts (
  PromptId int identity(1,1),
  PromptName varchar(20),
  PromptValue varchar(1000)
)
Insert into #Prompts (PromptName, PromptValue) Values ('ReportName', 'Active Variable Specs')
Insert into #Prompts (PromptName, PromptValue) Values ('Criteria', 'Some Criteria')
Insert into #Prompts (PromptName, PromptValue) Values ('GenerateTime', dbo.fnRS_TranslateString_New(@LangId, 36178, 'Created') + ': ' + convert(varchar(17), getdate(),109))
Insert into #Prompts (PromptName, PromptValue) Values ('Comment',dbo.fnRS_TranslateString_New(@LangId, 36179, 'Comment') )
Select * From #Prompts
Drop Table #Prompts
--Select @Now = Getdate()
Select @Now = Convert(DateTime, '2001-06-10 23:21:13.213')
-- Var Specs
Select  	 Effective_Date= CASE WHEN @TargetTimeZone is Not NULL THEN [dbo].[fnServer_CmnConvertFromDbTime] (Effective_Date,@TargetTimeZone) 
 	  	 ELSE Effective_Date END ,
 	  	 Expiration_Date= CASE WHEN @TargetTimeZone is Not NULL THEN [dbo].[fnServer_CmnConvertFromDbTime] (Expiration_Date,@TargetTimeZone)
 	  	 ELSE Expiration_Date END,
 	  	 vs.Var_Id,
 	  	 v.Var_Desc,
 	  	 vs.Prod_Id,
 	  	 Prod_Desc,
 	  	 Prod_Code,
 	  	 L_Entry,
 	  	 L_Reject,
 	  	 L_Warning,
 	  	 L_User,
 	  	 Target,
 	  	 U_User,
 	  	 U_Warning,
 	  	 U_Reject,
 	  	 U_Entry,
 	  	 Test_Freq,
 	  	 vs.Comment_Id
 From Var_Specs vs
 Left Join Variables v on v.Var_ID = vs.Var_Id
 Left Join Products p on p.Prod_Id = vs.Prod_Id
 where expiration_Date > @Now or Effective_Date > @Now
 Order By Effective_Date,Var_Desc,Prod_Code
--  Active Specs
Select  	 Effective_Date= CASE WHEN @TargetTimeZone is Not NULL THEN [dbo].[fnServer_CmnConvertFromDbTime] (Effective_Date,@TargetTimeZone)
 	  	 ELSE Effective_Date END,
 	  	 Expiration_Date= CASE WHEN @TargetTimeZone is Not NULL THEN [dbo].[fnServer_CmnConvertFromDbTime] (Expiration_Date,@TargetTimeZone)
 	  	 ELSE Expiration_Date END,
 	  	 p.Prop_Desc,
 	  	 a.Spec_Id,
 	  	 s.Spec_Desc,
 	  	 a.Char_Id,
 	  	 c.Char_Desc,
 	  	 L_Entry,
 	  	 L_Reject,
 	  	 L_Warning,
 	  	 L_User,
 	  	 Target,
 	  	 U_User,
 	  	 U_Warning,
 	  	 U_Reject,
 	  	 U_Entry,
 	  	 Test_Freq,
 	  	 a.Comment_Id
 From Active_Specs a
 Left Join Specifications s on s.Spec_Id = a.Spec_Id
 Left Join Characteristics c on c.Char_Id = a.Char_Id
 Left Join Product_Properties p on p.Prop_Id = s.Prop_Id
 where Expiration_Date > @Now or Effective_Date > @Now
 Order By Effective_Date,Spec_Desc,Char_Desc

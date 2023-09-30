Create Procedure [dbo].[spRS_IEGetComponentVersion]
 	 @ComponentType int, 	 
 	 @ComponentName varchar(255)
AS
DECLARE @COMPONENT_WEB_PAGE INT
DECLARE @COMPONENT_REPORT_TYPE INT
Select @COMPONENT_WEB_PAGE = 1
Select @COMPONENT_REPORT_TYPE = 2
If @ComponentType = @COMPONENT_WEB_PAGE
 	 Begin
 	  	 select version from report_webpages where Upper(LTrim(RTrim(Title))) = LTrim(RTrim(Upper(@ComponentName)))
 	 End
Else
 	 Begin
 	  	 select version from report_types where Upper(LTrim(RTrim(Description))) = LTrim(RTrim(Upper(@ComponentName)))
 	 End

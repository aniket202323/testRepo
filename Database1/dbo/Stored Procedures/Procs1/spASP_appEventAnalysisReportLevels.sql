CREATE procedure [dbo].[spASP_appEventAnalysisReportLevels]
  @EventType int,
  @IsCause int
AS
DECLARE @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
Create Table #ReportLevels (
  [Level] int,
  [Description] nVarChar(50)
)
If @EventType in (2,3) and @IsCause = 1 
  Insert Into #ReportLevels (Level, Description) Values (0, dbo.fnTranslate(@LangId, 34586, 'Location'))
If @EventType = 11 and @IsCause = 1
  Insert Into #ReportLevels (Level, Description) Values (0, dbo.fnTranslate(@LangId, 34587, 'Variable'))
If @IsCause = 1
  Begin
 	  	 Insert Into #ReportLevels (Level, Description) Values (1, dbo.fnTranslate(@LangId, 34588, 'Cause Level 1'))
 	  	 Insert Into #ReportLevels (Level, Description) Values (2, dbo.fnTranslate(@LangId, 34589, 'Cause Level 2'))
 	  	 Insert Into #ReportLevels (Level, Description) Values (3, dbo.fnTranslate(@LangId, 34590, 'Cause Level 3'))
 	  	 Insert Into #ReportLevels (Level, Description) Values (4, dbo.fnTranslate(@LangId, 34591, 'Cause Level 4'))
  End
Else
  Begin
 	  	 Insert Into #ReportLevels (Level, Description) Values (1, dbo.fnTranslate(@LangId, 34592, 'Action Level 1'))
 	  	 Insert Into #ReportLevels (Level, Description) Values (2, dbo.fnTranslate(@LangId, 34593, 'Action Level 2'))
 	  	 Insert Into #ReportLevels (Level, Description) Values (3, dbo.fnTranslate(@LangId, 34594, 'Action Level 3'))
 	  	 Insert Into #ReportLevels (Level, Description) Values (4, dbo.fnTranslate(@LangId, 34595, 'Action Level 4'))
  End 
Select * From #ReportLevels 
  Order By Level ASC

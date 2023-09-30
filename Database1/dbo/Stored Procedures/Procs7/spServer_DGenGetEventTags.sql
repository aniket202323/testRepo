CREATE PROCEDURE dbo.spServer_DGenGetEventTags
AS
-- Interval Is In Minutes
-- Types
 	 -- 1) Increments By 1 Starting From InitialValue Every Interval (Minutes)
 	 -- 2) Increments By 1 Starting From InitialValue Every Interval (Minutes), Starts Back At 1 When MaxValue Is Reached
 	 -- 3) Transitions From FromValue To ToValue Every Interval (Minutes)
 	 -- 4) Writes InitialValue Every Interval (Minutes)
 	 -- 5) Toggles Between FromValue And ToValue Every Interval (Minutes)
Declare
  @DefaultHistorian nVarChar(100),
  @TableId int
Select @TableId = NULL
Select @TableId = Id From sysobjects Where (Name = 'DataGeneratorConfig') And (Type = 'U')
If (@TableId Is NULL)
  Return
Select @DefaultHistorian = NULL
Select @DefaultHistorian = COALESCE(Alias,Hist_Servername) From Historians Where Hist_Default = 1
If (@DefaultHistorian Is NULL)
  Select @DefaultHistorian = ''
Select Tag,Interval,Offset,Type,InitialValue,MaxValue,DelayAfterMax,FromValue,ToValue ,
       TagOnly = 
        CASE CharIndex('\\',Tag)
          When 0 Then Tag
          When 1 Then SubString(Tag,CharIndex('\',SubString(Tag,3,100)) + 3,100)
          Else
            ''
        END,
       NodeName = 
        CASE CharIndex('\\',Tag)
          When 0 Then @DefaultHistorian
          When 1 Then SubString(Tag,3,CharIndex('\',SubString(Tag,3,100)) - 1)
          Else
            ''
        END
From DataGeneratorConfig Order By Type,Tag

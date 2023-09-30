Create Procedure [dbo].spRS_GetEventDescriptionByCode
 	 @InputString varchar(8000)
AS
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
-- Get Common Prompts
Declare @sAlarm VARCHAR(100)
SET @sAlarm = dbo.fnTranslate(@LangId, 34902, 'Alarm')
Declare @T Table (id int identity (1, 1), FullCode varchar(10), EventCode varchar(1), EventKey int, [Desc] varchar(5000))
Declare @INstr VarChar(7999)
Declare @Comma int
Declare @Id varchar(10)
Declare @EC varchar(1), @EK int
Select @INstr = @InputString + ','
While (Datalength(LTRIM(RTRIM(@INstr))) > 1) 
  Begin
 	 Select @Comma = CharIndex(',', @Instr)
 	 Select @Id = SubString(@INstr,1,@Comma - 1)
 	 Select @EC = SubString(@Id, 1, 1)
    Select @EK = SubString(@Id, 2, DataLength(@Id) - 1)
    insert into @T (FullCode, EventCode, EventKey) Values (@Id, @EC, @EK)
 	 Select @Instr = Right(@Instr, DataLength(@Instr) - @Comma)
  End
Declare @Desc varchar(5000), @row int
Declare MyCursor  CURSOR
  For ( Select Id, EventCode, EventKey From @T )
  For Read Only
  Open MyCursor  
  Fetch Next From MyCursor Into @row, @EC, @EK
  While (@@Fetch_Status = 0)
    Begin
 	  	 --Select @ET
 	  	 if @EC = 'A'
 	  	  	 Select @Desc =  Coalesce(pu.PU_Desc + '->', '') + v.var_desc + ' ' + @sAlarm
 	  	  	 From variables v
 	  	  	  	 Join Prod_units pu on pu.pu_id = v.pu_id 
 	  	  	 Where v.var_id = @Ek
 	  	 Else If @EC = 'C'
 	  	  	 Select @Desc = dbo.fnTranslate(@LangId, 34903, 'Crew Schedule')
 	  	 Else If @EC = 'E'
 	  	  	 Select @Desc = Coalesce(pu.PU_Desc + '->', '') + coalesce(es.event_subtype_desc, et.et_desc)
 	  	  	 From Event_Configuration ec
 	  	  	  	 Join Event_Types et on et.et_id = ec.et_id
 	  	  	  	 Left Outer Join Prod_Units pu on pu.pu_id = ec.pu_id
 	  	  	  	 Left Outer Join Event_Subtypes es on es.event_subtype_id = ec.event_subtype_id 
 	  	  	 Where ec.ec_Id = @Ek
 	  	 update @t Set [Desc] = @Desc where Id = @Row
 	  	 Fetch Next From MyCursor Into @row, @EC, @EK
    End 
Close MyCursor
Deallocate MyCursor
Select FullCode as [IdCode], [Desc] as [QualifiedDescription] From @T

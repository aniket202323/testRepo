CREATE FUNCTION dbo.fnCMN_GetEngineeringUnitsByUnit(@Unit INT) 
     RETURNS @EngineeringUnits Table (AmountEngineeringUnits nvarchar(25), ItemEngineeringUnits nvarchar(25), TimeEngineeringUnits int, TimeUnitDesc nvarchar(25))
AS 
Begin
Declare @AmountEngineeringUnits nvarchar(25)
Declare @ItemEngineeringUnits nvarchar(25)
Declare @TimeEngineeringUnits int
Declare @TimeUnitDesc nvarchar(25)
Declare @Production_Variable Int
Select @AmountEngineeringUnits = NULL
Select @ItemEngineeringUnits = NULL
Select 
@Production_Variable = Production_Variable,
@TimeEngineeringUnits = Production_Rate_TimeUnits
From Prod_Units Where PU_Id = @Unit
Select @TimeUnitDesc =
     Case @TimeEngineeringUnits
          When 0 Then 'Hour'
          When 1 Then 'Minute'
          When 2 Then 'Second'
          When 3 Then 'Day'
          Else ''
     End
If @Production_Variable Is Null
  Begin
 	 -- Event Based Production
 	 Select @ItemEngineeringUnits = s.event_subtype_desc,
 	        @AmountEngineeringUnits = s.dimension_x_eng_units
 	   from event_configuration e 
 	   join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
 	   where e.pu_id = @Unit and 
 	         e.et_id = 1
  End
Else
  Begin
 	 -- Time Based Production
 	 select @ItemEngineeringUnits = Eng_Units ,
 	 @AmountEngineeringUnits = Eng_Units
 	 from Variables where var_id = @Production_Variable
  End
     Insert Into @EngineeringUnits(AmountEngineeringUnits, ItemEngineeringUnits, TimeEngineeringUnits, TimeUnitDesc)
     Values(@AmountEngineeringUnits, @ItemEngineeringUnits, @TimeEngineeringUnits, @TimeUnitDesc)
     RETURN
END

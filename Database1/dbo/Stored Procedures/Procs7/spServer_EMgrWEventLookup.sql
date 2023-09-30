CREATE PROCEDURE dbo.spServer_EMgrWEventLookup
@PU_Id int,
@Fault_Code 	 nVarChar(50),
@Measure_Code  	 nVarChar(50),
@Type_Code     	 nVarChar(50),
@Event_Type      	 int,
@Waste_Event_Time  	 datetime,
@AutoCreate int,
@Source_PU_Id  	 int OUTPUT,
@Fault_Id  	 int OUTPUT,
@Measure_Id 	 int OUTPUT,
@Type_Id 	 int OUTPUT,
@Reason_Id1  	 int OUTPUT,
@Reason_Id2  	 int OUTPUT,
@Reason_Id3  	 int OUTPUT,
@Reason_Id4  	 int OUTPUT,
@Event_Id 	  	 int OUTPUT,
@Valid_Event    int OUTPUT,
@Conversion     real output
AS
select @Valid_Event = 1
Select @Fault_Id = NULL
Select @Fault_Id = WEFault_Id,
       @Source_PU_Id = Source_PU_Id,
       @Reason_Id1 = Reason_Level1,
       @Reason_Id2 = Reason_Level2,
       @Reason_Id3 = Reason_Level3,
       @Reason_Id4 = Reason_Level4
  From Waste_Event_Fault 
  Where (PU_Id = @PU_Id) And 
        (Upper(LTrim(RTrim(WEFault_Value))) = Upper(LTrim(RTrim(@Fault_Code))))
If @Fault_Id Is Null
  Begin
    Select @Fault_Id = WEFault_Id,
       @Source_PU_Id = Source_PU_Id,
       @Reason_Id1 = Reason_Level1,
       @Reason_Id2 = Reason_Level2,
       @Reason_Id3 = Reason_Level3,
       @Reason_Id4 = Reason_Level4
    From Waste_Event_Fault 
    Where (PU_Id = @PU_Id) And 
          (Upper(LTrim(RTrim(WEFault_Name))) = Upper(LTrim(RTrim(@Fault_Code))))
  End
if (@Fault_Id Is Null) and (@AutoCreate = 1)
  Begin
    Select @Fault_Id = WEFault_Id,
       @Source_PU_Id = Source_PU_Id,
       @Reason_Id1 = Reason_Level1,
       @Reason_Id2 = Reason_Level2,
       @Reason_Id3 = Reason_Level3,
       @Reason_Id4 = Reason_Level4
    From Waste_Event_Fault 
    Where (PU_Id = @PU_Id) And 
          (Upper(LTrim(RTrim(WEFault_Value))) = SubString(Upper(LTrim(RTrim(@Fault_Code))), 1, COL_LENGTH('Waste_Event_Fault','WEFault_Value')))
  End
if (@Fault_Id Is Null) and (@AutoCreate = 1)
 	 Begin
 	  	 exec spEM_PutWasteEventFault @PU_Id, NULL, NULL, @Fault_Code, @Fault_Code, NULL, NULL, NULL, NULL, 6
    Select @Fault_Id = WEFault_Id,
       @Source_PU_Id = Source_PU_Id,
       @Reason_Id1 = Reason_Level1,
       @Reason_Id2 = Reason_Level2,
       @Reason_Id3 = Reason_Level3,
       @Reason_Id4 = Reason_Level4
    From Waste_Event_Fault 
    Where (PU_Id = @PU_Id) And 
          (Upper(LTrim(RTrim(WEFault_Name))) = Upper(LTrim(RTrim(@Fault_Code))))
 	 End
-- Lookup the Measure ID
select @Measure_Id = null
select @Measure_Id = WEMT_Id from Waste_Event_Meas where PU_Id = @PU_Id and WEMT_Name = @Measure_Code
if (@Measure_Id is null and isnumeric(@Measure_Code) = 1)
  select @Measure_Id = WEMT_Id from Waste_Event_Meas where PU_Id = @PU_Id and WEMT_Id = convert(int,@Measure_Code)
select @Conversion = coalesce(Conversion, 1.0) from Waste_Event_Meas where WEMT_Id = @Measure_Id
if (@Conversion is NULL) or (@Conversion = 0.0) select @Conversion = 1.0
select @Type_Id = WET_Id from Waste_Event_Type where WET_Name = @Type_Code
If @Measure_Id is NULL
  Select @Measure_Id = 0
If @Type_Id is NULL
  Select @Type_Id = 0
If @Fault_Id Is Null
  Select @Fault_Id = 0
If @Source_PU_Id Is Null
  Select @Source_PU_Id = 0
If @Reason_Id1 Is Null
  Select @Reason_Id1 = 0
If @Reason_Id2 Is Null
  Select @Reason_Id2 = 0
If @Reason_Id3 Is Null
  Select @Reason_Id3 = 0
If @Reason_Id4 Is Null
  Select @Reason_Id4 = 0
if (@Event_Type = 1)
begin
  select @Event_Id = Event_Id from Events where [TimeStamp] = @Waste_Event_Time and pu_id = @pu_id
  if @Event_Id is NULL 
  begin
    select @Event_Id = 0
    select @Valid_Event = 0
  end
end
else if (@Event_Type = 2)
begin
  select @Event_Id = Event_Id from Events where [TimeStamp] = @Waste_Event_Time and pu_id = @pu_id
  if @Event_Id is NULL 
  begin
    select @Event_Id = 0
  end
end
else if (@Event_Type = 3)
begin
  select @Event_Id = Event_Id from Events where pu_id = @pu_id and [TimeStamp] = (select max([TimeStamp])from Events where [TimeStamp] <= @Waste_Event_Time and pu_id = @pu_id) 
  if @Event_Id is NULL 
  begin
    select @Event_Id = 0
  end
end
else
begin
  select @Event_Id = 0
end

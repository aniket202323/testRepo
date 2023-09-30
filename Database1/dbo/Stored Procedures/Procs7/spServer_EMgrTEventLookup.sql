CREATE PROCEDURE dbo.spServer_EMgrTEventLookup
@PU_Id int,
@Status_Code nVarChar(50),
@Fault_Code nVarChar(50),
@AutoCreate int,
@Source_PU_Id int OUTPUT,
@Status_Id int OUTPUT,
@Fault_Id int OUTPUT,
@Reason_Id1 int OUTPUT,
@Reason_Id2 int OUTPUT,
@Reason_Id3 int OUTPUT,
@Reason_Id4 int OUTPUT
AS
Select @Fault_Id = NULL
Select @Fault_Id = TEFault_Id,
       @Source_PU_Id = Source_PU_Id,
       @Reason_Id1 = Reason_Level1,
       @Reason_Id2 = Reason_Level2,
       @Reason_Id3 = Reason_Level3,
       @Reason_Id4 = Reason_Level4
  From Timed_Event_Fault 
  Where (PU_Id = @PU_Id) And 
        (Upper(LTrim(RTrim(TEFault_Value))) = Upper(LTrim(RTrim(@Fault_Code))))
If @Fault_Id Is Null
  Begin
    Select @Fault_Id = TEFault_Id,
           @Source_PU_Id = Source_PU_Id,
           @Reason_Id1 = Reason_Level1,
           @Reason_Id2 = Reason_Level2,
           @Reason_Id3 = Reason_Level3,
           @Reason_Id4 = Reason_Level4
      From Timed_Event_Fault 
      Where (PU_Id = @PU_Id) And 
            (Upper(LTrim(RTrim(TEFault_Name))) = Upper(LTrim(RTrim(@Fault_Code))))
  End
If (@Fault_Id Is Null) and (@AutoCreate = 1)
 	 Begin
    Select @Fault_Id = TEFault_Id,
           @Source_PU_Id = Source_PU_Id,
           @Reason_Id1 = Reason_Level1,
           @Reason_Id2 = Reason_Level2,
           @Reason_Id3 = Reason_Level3,
           @Reason_Id4 = Reason_Level4
      From Timed_Event_Fault 
      Where (PU_Id = @PU_Id) And 
            (Upper(LTrim(RTrim(TEFault_Value))) = SubString(Upper(LTrim(RTrim(@Fault_Code))), 1, COL_LENGTH('Timed_Event_Fault','TEFault_Value')))
  End
If (@Fault_Id Is Null) and (@AutoCreate = 1)
 	 Begin
 	  	 exec spEM_PutTimedEventFault @PU_Id, NULL, NULL, @Fault_Code, @Fault_Code, NULL, NULL, NULL, NULL, 6
    Select @Fault_Id = TEFault_Id,
       @Source_PU_Id = Source_PU_Id,
       @Reason_Id1 = Reason_Level1,
       @Reason_Id2 = Reason_Level2,
       @Reason_Id3 = Reason_Level3,
       @Reason_Id4 = Reason_Level4
    From Timed_Event_Fault 
    Where (PU_Id = @PU_Id) And 
          (Upper(LTrim(RTrim(TEFault_Name))) = Upper(LTrim(RTrim(@Fault_Code))))
 	 End
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
Select @Status_Id = TEStatus_Id 
  From Timed_Event_Status 
  Where (PU_Id = @PU_Id) And 
  (Upper(LTrim(RTrim(TEStatus_Value))) = Upper(LTrim(RTrim(@Status_Code))))
If @Status_Id Is Null
  Begin
    Select @Status_Id = TEStatus_Id 
      From Timed_Event_Status 
      Where (PU_Id = @PU_Id) And 
      (Upper(LTrim(RTrim(TEStatus_Name))) = Upper(LTrim(RTrim(@Status_Code))))
  End
If @Status_Id Is Null
  Select @Status_Id = 0

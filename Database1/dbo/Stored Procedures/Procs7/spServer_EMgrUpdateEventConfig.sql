CREATE PROCEDURE dbo.spServer_EMgrUpdateEventConfig
@PU_Id int,
@ModelNum int,
@FieldNum int,
@FieldValue nVarChar(100)
AS
Declare
  @EDModelId int,
  @ECId int,
  @EDFieldId int,
  @ECVId int
Select @EDModelId = NULL
Select @EDModelId = ED_Model_Id From ED_Models Where Model_Num = @ModelNum
If (@EDModelId Is NULL)
  Return
Select @ECId = NULL
Select @ECId = EC_Id From Event_Configuration Where (ED_Model_Id = @EDModelId) And (PU_Id = @PU_Id) And (Is_Active = 1)
If (@ECId Is NULL)
  Return
Select @EDFieldId = NULL
Select @EDFieldId = ED_Field_Id From ED_Fields Where (ED_Model_Id = @EDModelId) And (Field_Order = @FieldNum)
If (@EDFieldId Is NULL)
  Return
Select @ECVId = NULL
Select @ECVId = ECV_Id From Event_Configuration_Data Where (EC_Id = @ECId) And (ED_Field_Id = @EDFieldId)
If (@ECVId Is NULL)
  Return
Update Event_Configuration_Values Set Value = @FieldValue Where ECV_Id = @ECVId

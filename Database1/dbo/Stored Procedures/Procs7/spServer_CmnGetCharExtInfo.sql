CREATE PROCEDURE dbo.spServer_CmnGetCharExtInfo
@PUId int,
@ProdId int,
@PropId int,
@ExtendedInfo nVarChar(255) OUTPUT
 AS
Declare
  @CharId int
Select @ExtendedInfo = NULL
Select @CharId = NULL
select @CharId = Char_Id 
  From PU_Characteristics 
  Where (PU_Id = @PUId) And 
        (Prod_Id = @ProdId) And 
        (Prop_Id = @PropId)
If (@CharId Is Not NULL)
  Select @ExtendedInfo = Extended_Info From Characteristics Where (Char_Id = @CharId)
If (@ExtendedInfo Is NULL)
  Select @ExtendedInfo = ''

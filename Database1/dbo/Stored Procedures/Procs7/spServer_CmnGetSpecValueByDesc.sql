CREATE PROCEDURE dbo.spServer_CmnGetSpecValueByDesc
@PU_Id int,
@TimeStamp datetime,
@Spec_Desc nVarChar(100),
@Success int OUTPUT,
@SpecValue float OUTPUT
 AS
Declare
  @Prod_Id int,
  @Prop_Id int,
  @Spec_Id int,
  @Char_Id int,
  @Master_Unit int
Select @SpecValue = 1.0
Select @Success = 1
Select @Master_Unit = PU_Id From Prod_Units_Base Where PU_Id = @PU_Id
If (@Master_Unit Is Null)
  Select @Master_Unit = @PU_Id
Select @Prod_Id = Prod_Id 
  From Production_starts
  Where (PU_Id = @Master_Unit) And
        (Start_Time < @TimeStamp) And
        ((End_Time >= @TimeStamp) Or (End_Time Is Null))
If (@Prod_Id Is Null)
  Return
Select @Spec_Id = Spec_Id,
       @Prop_Id = Prop_Id
  From Specifications
  Where (Spec_Desc = @Spec_Desc)
If ((@Spec_Id Is Null) Or (@Prop_Id Is Null))
  Return
Select @Char_Id = Char_Id 
  From PU_Characteristics 
  Where ((PU_Id = @Master_Unit) Or (PU_Id Is Null)) And
        (Prod_Id = @Prod_Id) And 
        (Prop_Id = @Prop_Id)
If (@Char_Id Is Null)
  Return
Select @SpecValue = Convert(float,Target)
  From Active_Specs
  Where (Spec_Id = @Spec_Id) And
        (Char_Id = @Char_Id) And
        (Effective_Date <= @TimeStamp) And 
        ((Expiration_Date > @TimeStamp) Or (Expiration_Date Is Null))
If (@SpecValue Is Null)
  Select @SpecValue = 1.0

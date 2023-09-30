CREATE PROCEDURE dbo.spServer_CmnDecodeVarId
@EncodedTag nVarChar(1000),
@VarId int OUTPUT
AS
Declare
  @LineDesc nVarChar(255),
  @UnitDesc nVarChar(255),
  @VarDesc nVarChar(255),
  @Pos int,
  @PLId int,
  @PUId int
Select @Pos = CharIndex('.',@EncodedTag)
If (@Pos = 0)
  Return(1)
Select @LineDesc = SubString(@EncodedTag,1,@Pos - 1)
Select @EncodedTag = SubString(@EncodedTag,@Pos + 1,500)
Select @Pos = CharIndex('.',@EncodedTag)
If (@Pos = 0)
  Return(1)
Select @UnitDesc = SubString(@EncodedTag,1,@Pos - 1)
Select @VarDesc = SubString(@EncodedTag,@Pos + 1,500)
Select @PLId = NULL
Select @PLId = PL_Id From Prod_Lines_base Where (REPLACE(REPLACE(REPLACE(PL_Desc,'.',''),' ',''),';','') = @LineDesc)
If (@PLId Is NULL) 
  Return(1)
Select @PUId = NULL
Select @PUId = PU_Id From Prod_Units_base Where (PL_Id = @PLId) And (REPLACE(REPLACE(REPLACE(PU_Desc,'.',''),' ',''),';','') = @UnitDesc) 
If (@PUId Is NULL)
  Return(1)
Select @VarId = NULL
Select @VarId = Var_Id From Variables_Base Where (PU_Id = @PUId) And (REPLACE(REPLACE(REPLACE(Var_Desc,'.',''),' ',''),';','') = @VarDesc) 
If (@VarId Is NULL)
  Return(1)
Return(0)

CREATE PROCEDURE dbo.spServer_EMgrProdXRef
@PU_Id int,
@Prod_Code_XRef nVarChar(25),
@ShouldTryConvert int,
@Prod_Id int OUTPUT
 AS
Select @Prod_Id = NULL
Select @Prod_Id = Prod_Id From Prod_XRef Where (Prod_Code_XRef = @Prod_Code_XRef) and (PU_Id = @PU_Id)
If @Prod_Id Is Not Null
  Return
Select @Prod_Id = Prod_Id From Prod_XRef Where (Prod_Code_XRef = @Prod_Code_XRef) and (PU_Id Is Null)
If @Prod_Id Is Not Null
  Return
 	 
-- (Below) Code Added for Comma Seperated Prod Xref Codes
Select @Prod_Id = Prod_Id From Prod_XRef Where (Prod_Code_XRef Like (@Prod_Code_XRef + ',%')) and (PU_Id = @PU_Id)
If @Prod_Id Is Not Null
  Return
Select @Prod_Id = Prod_Id From Prod_XRef Where (Prod_Code_XRef Like ('%,' + @Prod_Code_XRef + ',%')) and (PU_Id = @PU_Id)
If @Prod_Id Is Not Null
  Return
Select @Prod_Id = Prod_Id From Prod_XRef Where (Prod_Code_XRef Like ('%,' + @Prod_Code_XRef + '%')) and (PU_Id = @PU_Id)
If @Prod_Id Is Not Null
  Return
Select @Prod_Id = Prod_Id From Prod_XRef Where (Prod_Code_XRef Like (@Prod_Code_XRef + ',%')) and (PU_Id Is NULL)
If @Prod_Id Is Not Null
  Return
Select @Prod_Id = Prod_Id From Prod_XRef Where (Prod_Code_XRef Like ('%,' + @Prod_Code_XRef + ',%')) and (PU_Id Is NULL)
If @Prod_Id Is Not Null
  Return
Select @Prod_Id = Prod_Id From Prod_XRef Where (Prod_Code_XRef Like ('%,' + @Prod_Code_XRef + '%')) and (PU_Id Is NULL)
If @Prod_Id Is Not Null
  Return
-- (Above) Code Added for Comma Seperated Prod Xref Codes
If (@ShouldTryConvert <> 1)
  Begin
    Select @Prod_Id = 1
    Return
  End
if (SELECT COUNT(*) FROM Prod_XRef WHERE isnumeric(Prod_Code_XRef) = 0 AND  PU_ID = @PU_Id) > 0
  Begin
    Select @Prod_Id = 1
    Return
  End
Select @Prod_Id = Prod_Id From Prod_XRef Where (Convert(float,Prod_Code_XRef) = Convert(float,@Prod_Code_XRef)) and (PU_Id = @PU_Id)
If @Prod_Id Is Not Null
  Return
if (SELECT COUNT(*) FROM Prod_XRef WHERE isnumeric(Prod_Code_XRef) = 0 AND  PU_ID IS NULL) > 0
  Begin
    Select @Prod_Id = 1
    Return
  End
Select @Prod_Id = Prod_Id From Prod_XRef Where (isnumeric(Prod_Code_XRef) = 1) and (Convert(float,Prod_Code_XRef) = Convert(float,@Prod_Code_XRef)) and (PU_Id Is Null)
If @Prod_Id Is Not Null
  Return
Select @Prod_Id = 1

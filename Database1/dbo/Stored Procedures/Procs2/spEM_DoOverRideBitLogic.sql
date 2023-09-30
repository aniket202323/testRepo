Create Procedure dbo.spEM_DoOverRideBitLogic
 	 @Bit 	        Int,
 	 @Value         nvarchar(25), 
 	 @OverRideBit   Int Output
As
  If  (@Value Is Null) or (Ltrim(Rtrim(@Value)) = '') or (Ltrim(Rtrim(@Value)) Is Null)
    Begin
     If @OverRideBit & @Bit = @Bit 
 	 Begin
          Select @OverRideBit = @OverRideBit ^ @Bit
 	 End
    End
  Else
   Begin 
    Select @OverRideBit = @OverRideBit | @Bit
   End

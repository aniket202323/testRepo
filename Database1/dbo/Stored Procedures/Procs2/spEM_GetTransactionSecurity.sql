CREATE PROCEDURE dbo.spEM_GetTransactionSecurity
@Trans_Id  int,
@PropOrVar int OUTPUT,
@PU_Id     int OUTPUT
AS
-- Set PU_Id = 0 (no Data)
-- PropOrVar 1 = Property
-- PropOrVar 2 = Variable
   SELECT @PU_Id = Prop_Id FROM Characteristics c
      JOIN  Trans_Properties tp ON c.char_Id = tp.Char_Id
      WHERE Trans_Id = @Trans_Id
   IF @PU_Id IS NULL
     Begin
 	  	 Select @PU_Id = Prop_Id 
 	  	   From Trans_Characteristics
 	    	 Where Trans_Id = @Trans_Id
     End
   IF @PU_Id IS NULL
     Begin
    	  	 SELECT @PU_Id = Prop_Id
 	  	  FROM Characteristics c
        JOIN  Trans_Metric_Properties tp ON c.char_Id = tp.Char_Id
        WHERE Trans_Id = @Trans_Id
     End
   SELECT @ProporVar = 1
   IF @PU_Id IS NULL
     Begin
 	 Select @PU_Id = PU_Id 
 	   From Trans_Products
 	   Where Trans_Id = @Trans_Id
 	   Select @PropOrVar = 3
     End
  IF @PU_Id IS NULL 
    BEGIN
 	 Select @PropOrVar = 2
 	 SELECT @PU_Id = PUG_Id from Variables v
 	     JOIN Trans_Variables tv ON tv.Var_Id = v.Var_Id
 	     WHERE Trans_Id = @Trans_Id
   End

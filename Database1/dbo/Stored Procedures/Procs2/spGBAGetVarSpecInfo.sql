Create Procedure dbo.spGBAGetVarSpecInfo
  @Var_Id int,
  @Prod_Id int,
  @STime datetime 
 AS
    BEGIN 
      SELECT * FROM Var_Specs WITH (index(Var_Specs_By_Var_Prod_Effect))
       WHERE (Var_Id = @Var_Id) AND
             (Prod_Id = @Prod_Id) AND
             (effective_date <= @Stime) AND
             ((expiration_date > @STime) OR (expiration_date IS NULL))
    END

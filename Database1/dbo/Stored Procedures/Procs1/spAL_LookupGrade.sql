Create Procedure dbo.spAL_LookupGrade
  @PU_Id int,
  @Result_On datetime,
  @Prod_Id int OUTPUT,
  @Prod_Code nvarchar(20) OUTPUT AS
  declare @Id int
  SELECT @Id = NULL
  -- Lookup the production start.
  SELECT @Id = s.Start_Id,
         @Prod_Id = s.Prod_Id,
         @Prod_Code = p.Prod_Code
    FROM Production_Starts s
    join Products p on p.prod_id = s.prod_id
    WHERE (s.PU_Id = @PU_Id) AND
          (s.Start_Time <= @Result_On) AND
          ((s.End_Time > @Result_On) OR (s.End_Time is NULL))
  IF @Id IS NULL RETURN(1)
  RETURN(100)

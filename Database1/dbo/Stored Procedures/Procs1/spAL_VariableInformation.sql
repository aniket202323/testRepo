Create Procedure dbo.spAL_VariableInformation
  @Var_Id int,
  @Sampling_Interval int OUTPUT,
  @Event_Type tinyint OUTPUT,
  @Parent_Var_Desc nvarchar(25) OUTPUT,
  @Parent_Unit_Desc nvarchar(25) OUTPUT,
  @Parent_Line_Desc nvarchar(25) OUTPUT,
  @Sampling_Type tinyint OUTPUT AS
  -- Declare local vaiables.
  DECLARE @Parent_Var_Id int
  -- Obtain information about variable in question.
  SELECT @Parent_Var_Id = NULL
  SELECT @Sampling_Interval = Sampling_Interval,
         @Event_Type = Event_Type,
         @Parent_Var_Id = PVar_Id,
         @Sampling_Type = Sampling_Type
    FROM Variables
    WHERE (Var_Id = @Var_Id)
  -- Obtain information about parent variable.
  IF @Parent_Var_Id IS NULL
    SELECT @Parent_Var_Desc  = '',
           @Parent_Unit_Desc = '',
           @Parent_Line_Desc = ''
  ELSE
    SELECT @Parent_Var_Desc  = v.Var_desc,
           @Parent_Unit_Desc = u.PU_Desc,
           @Parent_Line_Desc = l.PL_Desc
      FROM Variables v, Prod_Units u, Prod_Lines l
      WHERE (v.Var_Id = @Parent_Var_Id) AND
            (u.PU_Id = v.PU_Id) AND
            (l.PL_Id = u.PL_Id)
  -- Return success.
  RETURN(100)

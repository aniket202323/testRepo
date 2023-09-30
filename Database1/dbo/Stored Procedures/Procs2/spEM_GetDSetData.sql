CREATE PROCEDURE dbo.spEM_GetDSetData
  @DSet_Id int
  AS
  --
  -- Declare local variables.
  --
  DECLARE @Timestamp Datetime_ComX,
          @Prod_Id   int
  --
  -- Initialize local variables.
  --           
  SELECT @Timestamp = Timestamp,
         @Prod_Id   = Prod_Id
    FROM GB_DSet WHERE DSet_Id = @DSet_Id
  --
  -- Return data set header information.
  --
  SELECT Timestamp = @Timestamp,
         Prod_Id   = @Prod_Id,
         User_Id   = 1
  --
  -- Return the data set data.
  --
  SELECT d.Var_Id,
         d.Value,
         v.U_Entry,
         v.U_Reject,
         v.U_Warning,
         v.U_User,
         v.Target,
         v.L_User,
         v.L_Warning,
         v.L_Reject,
         v.L_Entry,
 	  	  v.L_Control,
 	  	  v.T_Control,
 	  	  v.U_Control
    FROM GB_Dset_Data d
    INNER JOIN Var_Specs v ON
      (v.Var_Id = d.Var_Id) AND
      (v.Prod_Id = @Prod_Id) AND
      (v.Effective_Date <= @Timestamp) AND
      ((v.Expiration_Date IS NULL) OR
       ((v.Expiration_Date IS NOT NULL) AND (v.Expiration_Date > @Timestamp)))
    WHERE d.DSet_Id = @DSet_Id

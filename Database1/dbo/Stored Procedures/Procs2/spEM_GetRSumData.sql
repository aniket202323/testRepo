CREATE PROCEDURE dbo.spEM_GetRSumData 
  @RSum_Id int,
  @DecimalSep     nVarChar(2) = '.'
  AS
  --
  -- Declare local variables.
  --
  DECLARE @Start_Time Datetime_ComX,
          @End_Time   Datetime_ComX,
          @Prod_Id    int,
          @Duration   Float_Natural,
          @In_Warning Float_Pct,
          @In_Limit   Float_Pct,
          @Conf_Index Float_Pct
  --
  -- Initialize local variables.
  --           
  SELECT @Start_Time = Start_Time,
         @End_Time   = End_Time,
         @Prod_Id    = Prod_Id,
         @Duration   = Duration,
         @In_Warning = In_Warning,
         @In_Limit   = In_Limit,
         @Conf_Index = Conf_Index
    FROM GB_RSum WHERE RSum_Id = @RSum_Id
  --
  -- Return data set header information.
  --
  SELECT Start_Time = @Start_Time,
         End_Time   = @End_Time,
         Prod_Id    = @Prod_Id,
         Duration   = @Duration,
         In_Warning = @In_Warning,
         In_Limit   = @In_Limit,
         Conf_Index = @Conf_Index
  --
  -- Return the data set data.
  --
  SELECT d.Var_Id,
 	  	 [Value] = REPLACE(d.Value, '.', @DecimalSep),
 	  	 d.In_Warning,
 	  	 d.In_Limit,
 	  	 Cpk = IsNull(d.Cpk,0),
 	  	 d.StDev,
 	  	 d.Conf_Index,
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
 	  	 v.U_Control,
 	  	 Cp = IsNull(d.Cp,0),
 	  	 Pp = IsNull(d.Pp,0),
 	  	 Ppk = IsNull(d.Ppk,0)
    FROM GB_RSum_Data d
    Left JOIN Var_Specs v ON
      (v.Var_Id = d.Var_Id) AND
      (v.Prod_Id = @Prod_Id) AND
      (v.Effective_Date <= @Start_Time) AND
      ((v.Expiration_Date IS NULL) OR
       ((v.Expiration_Date IS NOT NULL) AND (v.Expiration_Date > @Start_Time)))
    WHERE d.RSum_Id = @RSum_Id

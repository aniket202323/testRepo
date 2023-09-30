CREATE PROCEDURE dbo.spServer_CmnSavePSVar
@RSum_Id int,
@Var_Id int,
@Value nVarChar(30),
@In_Warning float,
@In_Limit float,
@Conf_Index float,
@Stdev float,
@Pp float,
@Cp float,
@Ppk float,
@Cpk float,
@Num_Values int,
@Minimum float,
@Maximum float
 AS
If (@Pp < 0.0)
  Select @Pp = NULL
If (@Cp < 0.0)
  Select @Cp = NULL
If (@Ppk < 0.0)
  Select @Ppk = NULL
If (@Cpk < 0.0)
  Select @Cpk = NULL
Insert Into GB_RSum_Data (RSum_Id,Var_Id,Value,In_Warning,In_Limit,Conf_Index,Stdev,Pp,Cp,Ppk,Cpk,Num_Values,Minimum,Maximum)
  Values (@RSum_Id,@Var_Id,@Value,@In_Warning,@In_Limit,@Conf_Index,@Stdev,@Pp,@Cp,@Ppk,@Cpk,@Num_Values,@Minimum,@Maximum)

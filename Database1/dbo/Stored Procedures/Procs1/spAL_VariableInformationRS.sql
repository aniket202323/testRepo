Create Procedure dbo.spAL_VariableInformationRS
  @Var_Id int,
  @TestId BigInt,
  @ColApproverId Int,
  @ProdId 	  	 Int,
  @ResultOn 	  	 DateTime
AS
DECLARE
 	 @Sampling_Interval int,
 	 @Precision int,
 	 @Event_Type tinyint,
 	 @Parent_Var_Desc nvarchar(25),
 	 @Parent_Unit_Desc nvarchar(25),
 	 @Parent_Line_Desc nvarchar(25),
 	 @Sampling_Type tinyint,
 	 @EntryByUserName 	  	  	 nVarChar(50),
 	 @ApproverUserName 	  	  	 nVarChar(50),
 	 @ColumnApproverUserName 	 nVarChar(50),
 	 @sLCL nvarchar(25),
 	 @sTCL nvarchar(25),
 	 @sUCL nvarchar(25),
 	 @lTFQ int,
 	 @PropertyDesc 	 nVarChar(255),
 	 @SpecDesc nVarChar(100),
 	 @SpecId  Int
  SELECT @ResultOn = dbo.fnServer_CmnConvertToDbTime(@resulton,'UTC')
  SELECT @EntryByUserName = 'N/A'
  SELECT @ApproverUserName = 'N/A'
  SELECT @ColumnApproverUserName = 'N/A'
  -- Declare local vaiables.
  DECLARE @Parent_Var_Id int
  -- Obtain information about variable in question.
  SELECT @Parent_Var_Id = NULL
  SELECT @Sampling_Interval = Sampling_Interval,
         @Event_Type = Event_Type,
         @Parent_Var_Id = PVar_Id,
         @Sampling_Type = Sampling_Type,
         @SpecId = Spec_Id,
 	  	  @Precision = Var_Precision 
    FROM Variables
    WHERE (Var_Id = @Var_Id)
  SELECT @EntryByUserName = ISNULL(u.username,'N/A'),
 	  	  @ApproverUserName = ISNULL(u2.username,'N/A')
 	 FROM Tests t
 	 Left JOIN Users u on u.User_Id = t.Entry_By 
 	 Left JOIN Users u2 on u2.User_Id = t.second_user_id
 	 WHERE t.Test_Id = @TestId 
 	 
  SELECT @ColumnApproverUserName = ISNULL(u.username,'N/A')
    From Users u
     WHERE u.User_Id = @ColApproverId
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
IF Exists(select 1 from  Test_Sigma_Data tsd WHERE tsd.Test_Id = @TestId)
BEGIN
 	 SELECT 	  	 @sLCL = ltrim(str(tsd.Mean - 3 * tsd.sigma,25,@Precision)),
 	  	  	  	 @sTCL =ltrim(str(tsd.Mean,25,@Precision)),
 	  	  	  	 @sUCL = ltrim(str(tsd.Mean + 3 * tsd.sigma,25,@Precision))
 	  	 FROM Test_Sigma_Data tsd
 	  	 WHERE tsd.Test_Id = @TestId 
 	 SELECT 	 @lTFQ = vs.Test_Freq
 	  	 From Var_Specs vs
 	  	 WHERE Var_Id = @Var_Id and Prod_Id = @ProdId and Effective_Date <= @ResultOn 
 	  	  	 and (vs.Expiration_Date > @ResultOn or vs.Expiration_Date  is null)
END
ELSE
BEGIN
 	 SELECT 	  @sLCL = vs.L_Control,
 	  	  	  	 @sTCL =vs.T_Control,
 	  	  	  	 @sUCL = vs.U_Control,
 	  	  	  	 @lTFQ = vs.Test_Freq
 	  	 From Var_Specs vs
 	  	 WHERE Var_Id = @Var_Id and Prod_Id = @ProdId and Effective_Date <= @ResultOn 
 	  	  	 and (vs.Expiration_Date > @ResultOn or vs.Expiration_Date  is null)
END
Select @PropertyDesc = pp.Prop_Desc, @SpecDesc = s.Spec_Desc
  FROM Specifications s 
  Join Product_Properties pp on pp.Prop_Id = s.Prop_Id
  Where s.Spec_Id = @SpecId
If @PropertyDesc is NULL
  Select @PropertyDesc = 'No Property'
If @SpecDesc is NULL
  Select @SpecDesc = 'No Specification'
Select @PropertyDesc = @PropertyDesc + '\' + @SpecDesc
IF @lTFQ Is Null and @Event_Type = 1
BEGIN
 	 SELECT @lTFQ = @Sampling_Interval
END
SELECT  Sampling_Interval = @Sampling_Interval,
 	  	  	 Event_Type = @Event_Type,
 	  	  	 Parent_Var_Desc = @Parent_Var_Desc,
 	  	  	 Parent_Unit_Desc = @Parent_Unit_Desc,
 	  	  	 Parent_Line_Desc = @Parent_Line_Desc,
 	  	  	 Sampling_Type = isnull(@Sampling_Type,0),
 	  	  	 EntryByUserName = @EntryByUserName,
 	  	  	 ApproverUserName = @ApproverUserName,
 	  	  	 ColumnApproverUserName = @ColumnApproverUserName,
 	  	  	 sLCL = isnull(@sLCL,''),
 	  	  	 sTCL = isnull(@sTCL,''),
 	  	  	 sUCL = isnull(@sUCL,''),
 	  	  	 lTFQ = isnull(@lTFQ,0),
 	  	  	 PropertyDesc = @PropertyDesc

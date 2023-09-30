-- DESCRIPTION: spXLA_VarSpecInfo() combines spXLAGetVarSpecInfo and additional lookups into a single stored procedure.
-- @DecimalSep is used to set the return numeric string value to desired reginal format
-- MT/6-10-2002
--
-- ECR #25128: mt/3-13-2003: GBDB doesn't enforce unique Var_Desc across entire database, mus handle duplcate Var_desc via code
-- ECR #31165: mt/8-18-2006: Added fields Upper & Lower & Target Control
--
CREATE PROCEDURE dbo.[spXLA_VarSpecInfo_Bak_177]
 	   @Var_Id 	 Int
 	 , @Var_Desc 	 Varchar(50)
    , @Prod_Id  	  Int
  	  , @Prod_Code  	  Varchar(50)
 	 , @Start_Time 	 DateTime 
 	 , @DecimalSep 	 Varchar(1)= '.'
 	 , @InTimeZone 	 varchar(200) = null
AS
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
--  Set the default Decimal Separator.
If @DecimalSep Is NULL SET @DecimalSep = '.' 
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
DECLARE @Row_Count 	 Int
DECLARE @Data_Type_Id 	 Int
-- First Validify the Variable Input
SELECT @Row_Count = 0
-- ECR #25128: mt/3-13-2003: GBDB doesn't enforce unique Var_Desc across entire database, mus handle duplcate Var_desc via code
If @Var_Desc Is NULL AND @Var_Id Is NULL
  BEGIN
    SELECT [ReturnStatus] = -35 	  	 --input variable NOT SPECIFIED
    RETURN
  END
Else If @Var_Desc Is NULL --we have @Var_Id
  BEGIN
    SELECT @Var_Desc = v.Var_Desc, @Data_Type_Id = v.Data_Type_Id FROM Variables v WHERE v.Var_Id = @Var_Id
    SELECT @Row_Count = @@ROWCOUNT
    If @Row_Count = 0
      BEGIN
        SELECT [ReturnStatus] = -30 	 --specified variable NOT FOUND
        RETURN
      END
    --EndIf:Count=0
  END
Else --we have @Var_Desc
  BEGIN
    SELECT @Var_Id = v.Var_Id, @Data_Type_Id = v.Data_Type_Id FROM Variables v WHERE v.Var_Desc = @Var_Desc
    SELECT @Row_Count = @@ROWCOUNT
    If @Row_Count <> 1
      BEGIN
        If @Row_Count = 0 
          SELECT [ReturnStatus] = -30 	 --specified variable NOT FOUND
        Else --toomany Var_Desc
          SELECT [ReturnStatus] = -33 	 --DUPLICATE FOUND in Var_Desc
        --EndIf:Count
        RETURN
      END
    --EndIf:Count<>1
  END
--EndIf:Both @Var_Id and @Var_Desc null
If ISNUMERIC(@Data_Type_Id) = 0
  BEGIN 
    SELECT ReturnStatus = -20 	  	 --"Illegal data type"
    RETURN
  END
--EndIf:Numeric
--Validate the Product Input; Prod_Code is Unique, no duplication expected
SELECT @Row_Count = 0
If @Prod_Code Is NOT NULL
  BEGIN
    SELECT @Prod_Id = p.Prod_Id FROM Products p WHERE p.Prod_Code = @Prod_Code
    SELECT @Row_Count = @@ROWCOUNT
END
Else If @Prod_Id Is NOT NULL
  BEGIN
    SELECT @Prod_Code = p.Prod_Code FROM Products p WHERE p.Prod_Id = @Prod_Id
    SELECT @Row_Count = @@ROWCOUNT
  END
Else --both @Prod_Id and @Prod_Code are null (safeguard only; AddIn should have ruled this out)
  BEGIN
    SELECT ReturnStatus = -85 	  	 --"No product Specified"
    RETURN
  END
--EndIf:Product
If @Row_Count = 0
  BEGIN
    SELECT ReturnStatus = -80 	  	 --"Product Specified Not Found"
    RETURN
  END
--EndIf:Row_Count
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
If @DecimalSep = '.' AND @Data_Type_Id = 2 
  BEGIN 
    SELECT v.VS_Id 
         , Effective_Date = dbo.fnServer_CmnConvertFromDbTime(v.Effective_Date,@InTimeZone)
         , Expiration_Date = dbo.fnServer_CmnConvertFromDbTime(v.Expiration_Date,@InTimeZone)
         , v.Deviation_From
         , v.First_Exception
         , v.Test_Freq
         , v.AS_Id
         , v.Comment_Id
         , v.Var_Id
         , v.Prod_Id
         , v.Is_OverRiden
         , v.Is_Deviation
         , v.Is_OverRidable
         , v.Is_Defined
         , v.Is_L_Rejectable
         , v.Is_U_Rejectable
         , [L_Warning] 
         , [L_Reject] 
         , [L_Entry]  
         , [U_User]   
         , [Target]   
         , [L_User]   
         , [U_Entry]  
         , [U_Reject] 
         , [U_Warning]
         , [T_Control] 	 -- ECR #31165
         , [U_Control] 	 -- ECR #31165
         , [L_Control] 	 -- ECR #31165
         , t.Comment_Id as "Trans_Comment_Id"
         , [Data_Type_Id] = @Data_Type_Id
      FROM Var_Specs v WITH (INDEX(Var_Specs_By_Var_Prod_Effect))
      LEFT OUTER JOIN Transactions t ON t.Effective_Date = v.Effective_Date
     WHERE v.Var_Id = @Var_Id
       AND v.Prod_Id = @Prod_Id
       AND v.Effective_Date <= @Start_Time
       AND (v.Expiration_Date > @Start_Time OR v.Expiration_Date IS NULL)
  END
ELSE --Not default decimal separator, must set it to the specified regional decimal separator
  BEGIN 
    SELECT v.VS_Id 
         , Effective_Date = dbo.fnServer_CmnConvertFromDbTime(v.Effective_Date,@InTimeZone)
         , Expiration_Date = dbo.fnServer_CmnConvertFromDbTime(v.Expiration_Date,@InTimeZone)
         , v.Deviation_From
         , v.First_Exception
         , v.Test_Freq
         , v.AS_Id
         , v.Comment_Id
         , v.Var_Id
         , v.Prod_Id
         , v.Is_OverRiden
         , v.Is_Deviation
         , v.Is_OverRidable
         , v.Is_Defined
         , v.Is_L_Rejectable
         , v.Is_U_Rejectable
         , [L_Warning] = REPLACE(v.L_Warning, '.', @DecimalSep)
         , [L_Reject] = REPLACE(v.L_Reject, '.', @DecimalSep) 
         , [L_Entry] = REPLACE(v.L_Entry, '.', @DecimalSep)  
         , [U_User] = REPLACE(v.U_User, '.', @DecimalSep)   
         , [Target] = REPLACE(v.Target, '.', @DecimalSep)   
         , [L_User] = REPLACE(v.L_User, '.', @DecimalSep)   
         , [U_Entry] = REPLACE(v.U_Entry, '.', @DecimalSep)  
         , [U_Reject] = REPLACE(v.U_Reject, '.', @DecimalSep) 
         , [U_Warning] = REPLACE(v.U_Warning, '.', @DecimalSep)
         , [T_Control] = REPLACE(v.T_Control, '.', @DecimalSep) 	 -- ECR #31165
         , [U_Control] = REPLACE(v.U_Control, '.', @DecimalSep) 	 -- ECR #31165
         , [L_Control] = REPLACE(v.L_Control, '.', @DecimalSep) 	 -- ECR #31165
         , t.Comment_Id as "Trans_Comment_Id"
         , [Data_Type_Id] = @Data_Type_Id
      FROM Var_Specs v WITH (INDEX(Var_Specs_By_Var_Prod_Effect))
    LEFT OUTER JOIN Transactions t ON t.Effective_Date = v.Effective_Date
     WHERE v.Var_Id = @Var_Id
       AND v.Prod_Id = @Prod_Id
       AND v.Effective_Date <= @Start_Time
       AND (v.Expiration_Date > @Start_Time OR v.Expiration_Date IS NULL)
  END
--EndIf:@DecimalSep ....

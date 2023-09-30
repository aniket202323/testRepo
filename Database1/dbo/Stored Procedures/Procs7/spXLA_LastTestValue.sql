CREATE Procedure dbo.spXLA_LastTestValue
 	   @Var_Id 	 Integer
 	 , @Pu_Id 	 Integer
 	 , @DecimalSep 	 varchar(1)= '.'
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
--JG Added this for regional settings:
--  Must replace the period in the result value with a comma if the 
--  passed decimal separator is not a period.
If @DecimalSep is Null Set @DecimalSep = '.' 
DECLARE @DataType 	  	 Int
SELECT @DataType = Data_Type_Id FROM Variables WHERE Var_Id = @Var_Id
--JG END
DECLARE 	 @Test_Id 	 BigInt
DECLARE 	 @Canceled 	 TinyInt
DECLARE 	 @Result_On 	 DateTime
DECLARE 	 @Entry_On 	 DateTime                                                                                                                         
DECLARE 	 @Event_Id 	 Int 
DECLARE 	 @Entry_By 	 Int
DECLARE 	 @Comment_Id 	 Int
DECLARE 	 @Array_Id 	 Int
DECLARE 	 @Result 	  	 Varchar(25)
DECLARE 	 @Prod_Id 	 Int
--Get the most current row in dbo.Tests for a given variable: MSi/mt/8-23-2001
SELECT TOP 1 @Test_Id = T.Test_Id, @Canceled = T.Canceled, @Result_On = T.Result_On, @Entry_On = T.Entry_On
 	    , @Event_Id = T.Event_Id, @Var_Id = T.Var_Id, @Entry_By = T.Entry_By, @Comment_Id = T.Comment_Id
 	    , @Array_Id = T.Array_Id, 
           @Result = CASE 
                        WHEN @DecimalSep <> '.' and @DataType = 2 THEN REPLACE(T.Result, '.', @DecimalSep)
                        ELSE T.Result
                      END
      FROM  Tests T 
     WHERE  T.Var_Id = @Var_Id 
  ORDER BY  T.Result_On DESC 
--Get Product ID based on input PU_ID and data (@Result_On) just retrieved 
SELECT TOP 1  @Prod_Id = ps.Prod_Id 
        FROM  production_starts ps 
       WHERE  ps.Pu_id = @Pu_Id 
         AND  ps.start_time <= @Result_on 
         AND (ps.End_time > @Result_on OR ps.end_time is null)
-- Get the fields we care about (like those we get in Proficy Add-In's TestData By Specific Time's )
SELECT    @Test_Id as 'Test_Id'
 	  	 , @Canceled as 'Canceled'
 	  	 , [Result_On] = @Result_On at time zone @DBTz at time zone @InTimeZone
 	  	 , [Entry_On] = @Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	 , @Event_Id as 'Event_Id'
 	  	 , @Var_Id as 'Var_Id'
 	  	 , @Entry_By as 'Entry_By'
 	  	 , @Comment_Id as 'Comment_Id'
 	  	 , @Array_Id as 'Array_Id'
 	  	 , @Result as 'Result'
 	  	 , @Prod_Id as 'Prod_Id'

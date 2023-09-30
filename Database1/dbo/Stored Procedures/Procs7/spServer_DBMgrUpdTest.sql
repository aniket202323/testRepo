CREATE PROCEDURE dbo.spServer_DBMgrUpdTest
  @Var_Id  	  int,
  @User_Id       int,
  @Canceled      int,
  @New_Result 	  nVarChar(25),
  @Result_Year 	  int,
  @Result_Month 	  int,
  @Result_Day 	  int,
  @Result_Hour 	  int,
  @Result_Minute int,
  @Result_Second int,    
  @TransNum int, 	  	  	 -- NewParam
  @CommentId int, 	  	  	 -- NewParam
  @ArrayId int, 	  	  	  	 -- NewParam
  @EventId int OUTPUT, 	  	 -- NewParam
  @PU_Id 	  int 	       OUTPUT,
  @Test_Id 	  BigInt 	       OUTPUT,
  @Entry_Year 	  int     OUTPUT,
  @Entry_Month 	  int      OUTPUT,
  @Entry_Day 	  int      OUTPUT,
  @Entry_Hour 	  int      OUTPUT,
  @Entry_Minute 	  int      OUTPUT,
  @Entry_Second 	  int      OUTPUT,
  @SecondUserId int = NULL, -- NewParam
  @SignatureId  int = NULL
 AS
 DECLARE @Result_On 	         Datetime,
 	  	   @Entry_On 	  	  	 DateTime,
 	  	   @Rc 	  	  	  	 Int
 declare @HasHistory int
  Select @Entry_Year = 0
  Select @Entry_Month = 0 
  Select @Entry_Day = 0
  Select @Entry_Hour = 0
  Select @Entry_Minute = 0
  Select @Entry_Second 	 = 0
  Execute spServer_DBMgrEncodeDateTime    @Result_Year,@Result_Month, @Result_Day, @Result_Hour, @Result_Minute, @Result_Second, @Result_On    OUTPUT
  Execute  @Rc = spServer_DBMgrUpdTest2  @Var_Id, @User_Id,@Canceled,@New_Result,@Result_On,@TransNum, @CommentId,
 	  	  	  	  	  	  	  	  	  @ArrayId,@EventId  OUTPUT, @PU_Id  OUTPUT, @Test_Id OUTPUT,  @Entry_On 	   OUTPUT,@SecondUserId, @HasHistory, @SignatureId
  Execute spServer_DBMgrDecodeDateTime    @Entry_On, @Entry_Year    OUTPUT, @Entry_Month   OUTPUT, @Entry_Day     OUTPUT,
     	  	  	  	  	  	  	  	  	   @Entry_Hour    OUTPUT, @Entry_Minute  OUTPUT, @Entry_Second  OUTPUT
  --
  -- Return success.
  --
  RETURN(@Rc)

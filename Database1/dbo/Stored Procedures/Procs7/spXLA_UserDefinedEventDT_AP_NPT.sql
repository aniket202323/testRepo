-- DESCRIPTION: spXLA_UserDefinedEventDT_AP_NPT() 
--
-- ECR #27889 (mt/4-26-2004) 
--
CREATE PROCEDURE dbo.spXLA_UserDefinedEventDT_AP_NPT
 	   @Start_Time 	  	 DateTime
 	 , @End_Time 	  	 DateTime
 	 , @PU_Id 	  	 Int 	  	 
 	 , @Event_Subtype_Id 	 Int 	  	 
 	 , @SelectR1 	  	 Int
 	 , @SelectR2 	  	 Int
 	 , @SelectR3 	  	 Int
 	 , @SelectR4 	  	 Int
 	 , @SelectA1             Int
 	 , @SelectA2             Int
 	 , @SelectA3             Int
 	 , @SelectA4             Int
 	 , @Crew_Desc 	  	 Varchar(10)
 	 , @Shift_Desc 	  	 Varchar(10)
        , @Ack_Required         TinyInt
 	 , @Prod_Id 	  	 Int 
 	 , @Group_Id 	  	 Int
 	 , @Prop_Id 	  	 Int
 	 , @Char_Id 	  	 Int
 	 , @Is_AP_Filter 	  	 TinyInt
 	 , @TimeSort 	  	 TinyInt
 	 , @Username Varchar(50)
 	 , @Langid Int 
AS
 	 --Local query assistance
DECLARE @QueryType  	  	 TinyInt
DECLARE @SingleProduct 	  	 TinyInt 	 --1
DECLARE @Group 	  	  	 TinyInt --2
DECLARE @Characteristic 	  	 TinyInt 	 --3
DECLARE @GroupAndProperty 	 TinyInt --4
DECLARE @NoProductSpecified 	 TinyInt --5
 	 --Needed for Cursor ...
DECLARE @Prev_Ps_Start_Time     DateTime
DECLARE @Prev_Ps_End_Time       DateTime
DECLARE @Previous_End_Time 	 DateTime
DECLARE @Previous_Pu_Id 	  	 Int
DECLARE @Previous_Prod_Id  	 Int
DECLARE @Previous_ApProd_Id 	 Int
DECLARE @Original_Found 	         Int
DECLARE @Sum_Original_Found 	 Int
DECLARE @AP_Found 	  	 Int
DECLARE @Sum_AP_Found 	  	 Int
DECLARE @Saved_Start_Time 	 DateTime
DECLARE @Fetch_Count            Int
DECLARE @@Ps_Start_Time         DateTime
DECLARE @@Ps_End_Time           DateTime
DECLARE @@Start_Time            	 DateTime
DECLARE @@End_Time              	 DateTime
DECLARE @@Pu_Id                 	 Int
DECLARE @@Prod_Id 	  	 Int
DECLARE @@Applied_Prod_Id 	 Int
 	 --Needed for Crew,Shift filters
DECLARE @CrewShift 	  	 TinyInt
DECLARE @NoCrewNoShift 	  	 TinyInt
DECLARE @HasCrewNoShift 	  	 TinyInt
DECLARE @NoCrewHasShift 	  	 TinyInt
DECLARE @HasCrewHasShift 	 TinyInt
DECLARE @Unspecified varchar(50)
CREATE TABLE #Applied_Products (Pu_Id Int, Ps_Start_Time DateTime, Ps_End_Time DateTime NULL, Start_Time DateTime, End_Time DateTime, Prod_Id Int, Applied_Prod_Id Int NULL, Keep_Event TinyInt NULL)
CREATE TABLE #Prod_Starts (PU_Id Int, Prod_Id Int, Start_Time DateTime, End_Time DateTime NULL)
CREATE TABLE #Products (Prod_Id Int)
CREATE TABLE #TempUDE (
 	   UDE_Id              Int
        , UDE_Desc            Varchar(1000)
 	 , Start_Time          DateTime
 	 , End_Time            DateTime    NULL
        , Crew_Start          DateTime    NULL
        , Crew_End            DateTime    NULL
  	 , Duration            real        NULL
 	 , Event_Subtype_Id    Int         NULL
 	 , PU_Id               Int         NULL
 	 , R1_Id 	               Int         NULL
 	 , R2_Id 	               Int         NULL
 	 , R3_Id               Int         NULL
 	 , R4_Id               Int         NULL
 	 , A1_Id 	               Int         NULL
 	 , A2_Id               Int         NULL
        , A3_Id               Int         NULL
 	 , A4_Id               Int         NULL
        , Prod_Id             Int         NULL
        , Applied_Prod_Id     Int         NULL
 	 , Crew_Desc           Varchar(10) NULL
 	 , Shift_Desc          Varchar(10) NULL
        , Ack_By              Int         NULL
        , Ack_On              DateTime    NULL
 	 , Research_User_Id    Int         NULL
 	 , Research_Status_Id  Int         NULL
 	 , Modified_On         DateTime    NULL
 	 , Research_Open_Date  DateTime    NULL
 	 , Research_Close_Date DateTime    NULL
 	 , Comment_Id          Int         NULL
 	 , Cause_Comment_Id    Int         NULL
 	 , Action_Comment_Id   Int         NULL
 	 , Research_Comment_Id Int         NULL
 	 , NPT 	  	  	  	   tinyint     NULL
       )
--Define Crew,Shift Type
SELECT @NoCrewNoShift   = 1
SELECT @HasCrewNoShift  = 2
SELECT @NoCrewHasShift 	 = 3
SELECT @HasCrewHasShift 	 = 4
If @Crew_Desc Is NULL AND @Shift_Desc Is NULL           SELECT @CrewShift = @NoCrewNoShift
Else If @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL  SELECT @CrewShift = @HasCrewNoShift
Else If @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL  SELECT @CrewShift = @NoCrewHasShift
Else                                                    SELECT @CrewShift = @HasCrewHasShift
--EndIf @Crew_Desc 
--Figure Out Query Type Based ON Product Info given
-- NOTE: We DO NOT handle all possible NULL combinations of product parameters (@Prod_Id, @Group_Id, @Prop_Id, and @Char_Id.)
-- Proficy Add-In blocks out illegal combinations, and allows only these combination:
--     * Property AND Characteristic 
--     * Group Only
--     * Group, Propery, AND Characteristic
--     * Product Only
--     * No Product Information At All 
SELECT @SingleProduct 	  	 = 1
SELECT @Group 	  	  	 = 2
SELECT @Characteristic 	  	 = 3
SELECT @GroupAndProperty 	 = 4
SELECT @NoProductSpecified 	 = 5
--DECLARE @UserId 	 Int
--SELECT @UserId = User_Id
--FROM users
--WHERE Username = @Username
--
--EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
--
--SELECT @Unspecified = dbo.fnDBTranslate(@Langid, 38333, 'Unspecified')
If      @Prod_Id Is NOT NULL 	  	  	  	 SELECT @QueryType = @SingleProduct   	 --1
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NULL 	 SELECT @QueryType = @Group   	  	 --2
Else If @Prop_Id Is NOT NULL AND @Group_Id Is NULL 	 SELECT @QueryType = @Characteristic  	 --3
Else If @Prop_Id Is NOT NULL AND @Group_Id Is NOT NULL 	 SELECT @QueryType = @GroupAndProperty 	 --4
Else 	  	  	  	  	  	  	 SELECT @QueryType = @NoProductSpecified 	 --5
--EndIf
If @Is_AP_Filter = 1 GOTO APPLIED_PRODUCT_FILTER
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE
-- Get Product And Related Info from Production_Starts Table (NOTE: any product is a legitimate original product filter )
If @QueryType = @NoProductSpecified 	 --5
  BEGIN
    If @PU_Id Is NULL
      BEGIN
        INSERT INTO #prod_starts
          SELECT ps.PU_Id, ps.prod_id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
           WHERE Start_Time BETWEEN @Start_Time AND @End_Time
              OR End_Time BETWEEN @Start_Time AND @End_Time 
              OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is null)) 	 --MSi/MT/3-14-2001 	  	     
      END
    Else    --@PU_Id not null
      BEGIN
        INSERT INTO #prod_starts
          SELECT ps.PU_Id, ps.prod_id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
           WHERE (ps.PU_Id = @PU_Id AND  ps.PU_Id <> 0)
             AND (    Start_Time BETWEEN @Start_Time AND @End_Time 
                   OR End_Time BETWEEN @Start_Time AND @End_Time 
                   OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is null)) --change Start_Time & End_Time conditions ; MSi/MT/3-14-2001
                 )     
      END
    --EndIf @PU_Id
  END
Else If @QueryType = @SingleProduct   	 --1
  BEGIN
    If @PU_Id Is NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time    
            FROM production_starts ps
           WHERE Prod_Id = @Prod_Id 
             AND (   (Start_Time BETWEEN @Start_Time AND @End_Time) 
                  OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                  OR (Start_Time <= @Start_Time AND ((End_Time > @End_Time) OR (End_Time is NULL))) --change Start_Time & End_Time conditions ; MSi/MT/3-14-2001
                 )  
      END
    Else     --@PU_Id NOT NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
           WHERE (ps.PU_Id = @PU_Id AND  ps.PU_Id <> 0)
             AND Prod_Id = @Prod_Id 
             AND (   (Start_Time BETWEEN @Start_Time AND @End_Time) 
                  OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                  OR (Start_Time <= @Start_Time AND ((End_Time > @End_Time) OR (End_Time is NULL))) --change Start_Time & End_Time conditions ; MSi/MT/3-14-2001
                 )  
      END
    --EndIf @PU_Id
  END
Else 	  	  	  	  	  	 --It is not a single Product
  BEGIN
    If @QueryType = @Group   	  	  	 --2
      BEGIN
        INSERT INTO #Products
        SELECT Prod_Id  FROM Product_Group_Data  WHERE product_grp_id = @Group_Id
      END
    Else If @QueryType = @Characteristic  	 --3
      BEGIN
        INSERT INTO #Products
        SELECT DISTINCT Prod_Id  FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END
    Else 	  	  	  	  	 --Group and Property  
      BEGIN
        INSERT INTO #Products
        SELECT Prod_Id  FROM Product_Group_Data WHERE product_grp_id = @Group_Id
        INSERT INTO #Products
        SELECT DISTINCT Prod_Id FROM pu_characteristics  WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END
    If @PU_Id Is NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
            JOIN #Products p ON ps.Prod_Id = p.Prod_Id 
 	    WHERE (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	       OR (End_Time BETWEEN @Start_Time AND @End_Time) 
 	       OR (Start_Time <= @Start_Time AND ((End_Time > @End_Time) OR (End_Time is NULL)))
      END
    Else     --@PU_Id NOT NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
            JOIN #Products p ON ps.Prod_Id = p.Prod_Id 
           WHERE (ps.PU_Id = @PU_Id AND  ps.PU_Id <> 0)
 	      AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	  	    OR (End_Time BETWEEN @Start_Time AND @End_Time) 
 	  	    OR (Start_Time <= @Start_Time AND ((End_Time > @End_Time) OR (End_Time is NULL)))
                 )
      END
    --EndIf @PU_Id is NULL 
  END
--EndIf =5 Fill Out Product-Related Temp Tables
-- Get All The Detail Records We Care About
-- Insert Data Into #TempUDE Temp Table
If      @CrewShift = @NoCrewNoShift   GOTO NOCREW_NOSHIFT_ORIGINAL_INSERT
Else If @CrewShift = @HasCrewNoShift  GOTO HASCREW_NOSHIFT_ORIGINAL_INSERT
Else If @CrewShift = @NoCrewHasShift  GOTO NOCREW_HASSHIFT_ORIGINAL_INSERT
Else                                  GOTO HASCREW_HASSHIFT_ORIGINAL_INSERT
--EndIf:Crew,shift
NOCREW_NOSHIFT_ORIGINAL_INSERT:
  If @PU_Id Is NULL
    If @Ack_Required = 0 --
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT 
                 D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time <= ps.Start_Time Then ps.Start_Time Else D.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ps.End_Time
                                     When ps.End_Time Is NULL Then D.End_Time
                                     When ps.End_Time <= D.End_Time Then ps.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ps.Prod_Id, D.Ack_By, D.Ack_On, D.Research_User_Id, Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
      END  
    Else --Acknowleded data only
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT 
                 D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time <= ps.Start_Time Then ps.Start_Time Else D.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ps.End_Time
                                     When ps.End_Time Is NULL Then D.End_Time
                                     When ps.End_Time <= D.End_Time Then ps.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ps.Prod_Id, D.Ack_By, D.Ack_On, D.Research_User_Id, Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.Ack = 1
      END  
    --EndIf:@Ack_Required..
  Else    --@PU_Id NOT NULL
    If @Ack_Required = 0 
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT 
                 D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time <= ps.Start_Time Then ps.Start_Time Else D.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ps.End_Time
                                     When ps.End_Time Is NULL Then D.End_Time
                                     When ps.End_Time <= D.End_Time Then ps.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ps.Prod_Id, D.Ack_By, D.Ack_On, D.Research_User_Id, Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM  User_Defined_Events D
            JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.PU_Id = @PU_Id
      END
    Else --@Ack_Required > 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT 
                 D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time <= ps.Start_Time Then ps.Start_Time Else D.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ps.End_Time
                                     When ps.End_Time Is NULL Then D.End_Time
                                     When ps.End_Time <= D.End_Time Then ps.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ps.Prod_Id, D.Ack_By, D.Ack_On, D.Research_User_Id, Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM  User_Defined_Events D
            JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )AND D.PU_Id = @PU_Id AND D.Ack = 1
      END
    --EndIf;@Ack_Required..
  --EndIf @PU_Id
  GOTO CONTINUE_UDE_PROCESS
--End NOCREW_NOSHIFT_ORIGINAL_INSERT:
HASCREW_NOSHIFT_ORIGINAL_INSERT:
  If @PU_Id Is NULL
    If @Ack_Required = 0 --
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT 
                 D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time <= ps.Start_Time Then ps.Start_Time Else D.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ps.End_Time
                                     When ps.End_Time Is NULL Then D.End_Time
                                     When ps.End_Time <= D.End_Time Then ps.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ps.Prod_Id, C.Crew_Desc, C.Shift_Desc, D.Ack_By, D.Ack_On, D.Research_User_Id, Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM  User_Defined_Events D
            JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
        END
    Else --@Ack_Require > 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT 
                 D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time <= ps.Start_Time Then ps.Start_Time Else D.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ps.End_Time
                                     When ps.End_Time Is NULL Then D.End_Time
                                     When ps.End_Time <= D.End_Time Then ps.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ps.Prod_Id, C.Crew_Desc, C.Shift_Desc, D.Ack_By, D.Ack_On, D.Research_User_Id, Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.Ack = 1
        END
    --EndIf:@Ack_Required...
  Else    --@PU_Id NOT NULL
    If @Ack_Required = 0 
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT 
                 D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time <= ps.Start_Time Then ps.Start_Time Else D.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ps.End_Time
                                     When ps.End_Time Is NULL Then D.End_Time
                                     When ps.End_Time <= D.End_Time Then ps.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ps.Prod_Id, C.Crew_Desc, C.Shift_Desc, D.Ack_By, D.Ack_On, D.Research_User_Id, Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM  User_Defined_Events D
            JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc
             AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL) AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time) 
             AND C.PU_Id = @PU_Id
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.PU_Id = @PU_Id 
      END
    Else --@Ack_Required >0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT 
                 D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time <= ps.Start_Time Then ps.Start_Time Else D.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ps.End_Time
                                     When ps.End_Time Is NULL Then D.End_Time
                                     When ps.End_Time <= D.End_Time Then ps.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ps.Prod_Id, C.Crew_Desc, C.Shift_Desc, D.Ack_By, D.Ack_On, D.Research_User_Id, Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM  User_Defined_Events D
            JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc
             AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL) AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time) 
             AND C.PU_Id = @PU_Id
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.PU_Id = @PU_Id AND D.Ack = 1
      END
    --EndIf:@Ack_Required
  --EndIf @PU_Id
  GOTO CONTINUE_UDE_PROCESS
--End HASCREW_NOSHIFT_ORIGINAL_INSERT:
NOCREW_HASSHIFT_ORIGINAL_INSERT:
  If @PU_Id Is NULL
    If @Ack_Required = 0 --
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT 
                 D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time <= ps.Start_Time Then ps.Start_Time Else D.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ps.End_Time
                                     When ps.End_Time Is NULL Then D.End_Time
                                     When ps.End_Time <= D.End_Time Then ps.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ps.Prod_Id, C.Crew_Desc, C.Shift_Desc, D.Ack_By, D.Ack_On, D.Research_User_Id, Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc 
             AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL) AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
        END
    Else -- @Ack_Required > 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT 
                 D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time <= ps.Start_Time Then ps.Start_Time Else D.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ps.End_Time
                                     When ps.End_Time Is NULL Then D.End_Time
                                     When ps.End_Time <= D.End_Time Then ps.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ps.Prod_Id, C.Crew_Desc, C.Shift_Desc, D.Ack_By, D.Ack_On, D.Research_User_Id, Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc 
             AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL) AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.Ack = 1
        END
    --EndIf:@Ack_Required...
  Else    --@PU_Id NOT NULL
    If @Ack_Required = 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT 
                 D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time <= ps.Start_Time Then ps.Start_Time Else D.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ps.End_Time
                                     When ps.End_Time Is NULL Then D.End_Time
                                     When ps.End_Time <= D.End_Time Then ps.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ps.Prod_Id, C.Crew_Desc, C.Shift_Desc, D.Ack_By, D.Ack_On, D.Research_User_Id, Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM  User_Defined_Events D
            JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time) 
             AND C.PU_Id = @PU_Id
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.PU_Id = @PU_Id 
      END
    Else --@Ack_Required >0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT 
                 D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time <= ps.Start_Time Then ps.Start_Time Else D.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ps.End_Time
                                     When ps.End_Time Is NULL Then D.End_Time
                                     When ps.End_Time <= D.End_Time Then ps.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ps.Prod_Id, C.Crew_Desc, C.Shift_Desc, D.Ack_By, D.Ack_On, D.Research_User_Id, Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM  User_Defined_Events D
            JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time) 
             AND C.PU_Id = @PU_Id
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.PU_Id = @PU_Id AND D.Ack = 1
      END
    --EndIf:@Ack_Required...
  --EndIf @PU_Id
  GOTO CONTINUE_UDE_PROCESS
--End NOCREW_HASSHIFT_ORIGINAL_INSERT:
HASCREW_HASSHIFT_ORIGINAL_INSERT:
  If @PU_Id Is NULL
    If @Ack_Required = 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT 
                 D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time <= ps.Start_Time Then ps.Start_Time Else D.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ps.End_Time
                                     When ps.End_Time Is NULL Then D.End_Time
                                     When ps.End_Time <= D.End_Time Then ps.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ps.Prod_Id, C.Crew_Desc, C.Shift_Desc, D.Ack_By, D.Ack_On, D.Research_User_Id, Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_DesC
             AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL) AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time) 
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL) 
        END
    Else --@Ack_Required > 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT 
                 D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time <= ps.Start_Time Then ps.Start_Time Else D.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ps.End_Time
                                     When ps.End_Time Is NULL Then D.End_Time
                                     When ps.End_Time <= D.End_Time Then ps.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ps.Prod_Id, C.Crew_Desc, C.Shift_Desc, D.Ack_By, D.Ack_On, D.Research_User_Id, Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_DesC
             AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL) AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time) 
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL) AND D.Ack = 1
        END
    --EndIf:@Ack_Require...
  Else    --@PU_Id NOT NULL
    If @Ack_Required = 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT 
                 D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time <= ps.Start_Time Then ps.Start_Time Else D.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ps.End_Time
                                     When ps.End_Time Is NULL Then D.End_Time
                                     When ps.End_Time <= D.End_Time Then ps.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ps.Prod_Id, C.Crew_Desc, C.Shift_Desc, D.Ack_By, D.Ack_On, D.Research_User_Id, Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM  User_Defined_Events D
            JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
             AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL) AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)
             AND C.PU_Id = @PU_Id     
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.PU_Id = @PU_Id 
      END
    Else --@Ack_Required > 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT 
                 D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time <= ps.Start_Time Then ps.Start_Time Else D.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ps.End_Time
                                     When ps.End_Time Is NULL Then D.End_Time
                                     When ps.End_Time <= D.End_Time Then ps.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ps.Prod_Id, C.Crew_Desc, C.Shift_Desc, D.Ack_By, D.Ack_On, D.Research_User_Id, Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM  User_Defined_Events D
            JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
             AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL) AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)
             AND C.PU_Id = @PU_Id     
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.PU_Id = @PU_Id AND D.Ack = 1
      END
    --EndIf:@Ack_Required...
  --EndIf @PU_Id
  GOTO CONTINUE_UDE_PROCESS
--End HASCREW_HASSHIFT_ORIGINAL_INSERT:
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE  
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE  
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE  
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE  
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE  
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE  
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE  
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE  
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE  
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE  
APPLIED_PRODUCT_FILTER:
  --Get all relevant products and info from production_Start table
  If @PU_Id Is NULL
    BEGIN
      INSERT INTO #prod_starts
        SELECT ps.PU_Id, ps.prod_id, ps.Start_Time, ps.End_Time
          FROM production_starts ps
         WHERE Start_Time BETWEEN @Start_Time AND @End_Time OR End_Time BETWEEN @Start_Time AND @End_Time OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is null))
    END
  Else    --@PU_Id not null
    BEGIN
      INSERT INTO #prod_starts
        SELECT ps.PU_Id, ps.prod_id, ps.Start_Time, ps.End_Time
          FROM production_starts ps
         WHERE (ps.PU_Id = @PU_Id AND  ps.PU_Id <> 0)
           AND (    Start_Time BETWEEN @Start_Time AND @End_Time OR End_Time BETWEEN @Start_Time AND @End_Time OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is null))
               )     --change Start_Time & End_Time conditions ; MSi/MT/3-14-2001
    END
  --EndIf @PU_Id
  --Grab all of the "Specified" product(s), put them into Temp Table #Products
  BEGIN      
    If @QueryType = @Group
      BEGIN
         INSERT INTO #Products
         SELECT Prod_Id FROM Product_Group_Data WHERE Product_Grp_Id = @Group_Id
      END
    Else If @QueryType = @Characteristic
      BEGIN
         INSERT INTO #Products
         SELECT DISTINCT Prod_Id FROM Pu_Characteristics WHERE Prop_Id = @Prop_Id AND Char_Id = @Char_Id
      END
    Else If @QueryType = @GroupAndProperty
      BEGIN
         INSERT INTO #Products
         SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
 	  INSERT INTO #Products
         SELECT distinct Prod_Id FROM pu_characteristics WHERE Prop_Id = @Prop_Id AND char_id = @Char_Id
      END
    Else -- must be @OneProductFilter
      BEGIN
        INSERT INTO #Products
        SELECT Prod_Id = @Prod_Id
      END
    --EndIf
  END
  -- Get Rows From Events Table for "Products" that fit applied products criteria ... 
  --  When matched product has Applied_Product = NULL, we take that the original product is applied product.
  --  When matched product has Applied_Product <> NULL, include that product as applied product
  --  NOTE1: JOIN condition for Production_Starts consistent with AutoLog's )
  --  NOTE2: As of 3-25-2002 MSI Start_Time inEvents table are mostly null. This storec procedure will insert
  --         a dummy value of TimeStamp minus one second for null Start_Time. For Customers who are concern about correct 
  --         Start_Time, which affect correct time-dependent results, MSI will give them a script for one-time update of 
  --         the Events table. This update is time/disk-space consuming, thus, available upon request only.
  --Make TEMP TABLE: Split ANY PRODUCT In #Prod_Starts into individual events.
  INSERT INTO #Applied_Products ( Pu_Id, Ps_Start_Time, Ps_End_Time, Start_Time, End_Time, Prod_Id, Applied_Prod_Id )
      SELECT e.Pu_Id, ps.Start_Time, ps.End_Time, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, ps.Prod_Id, e.Applied_Product 
        FROM #Prod_Starts ps 
        JOIN Events e ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL ) AND ps.Pu_Id = e.Pu_Id 
    ORDER BY e.Pu_Id, ps.Start_Time, e.Start_Time, ps.Prod_Id
  -- Use Cursor to track the individual events in #Applied_Products 
  DECLARE TCursor INSENSITIVE CURSOR 
    FOR ( SELECT Pu_Id, Ps_Start_Time, Ps_End_Time, Start_Time, End_Time, Prod_Id, Applied_Prod_Id FROM #Applied_Products )
    FOR READ ONLY
  --END Declare
OPEN_CURSOR_FOR_PROCESSING:
  -- Initialize local variables ......
  SELECT @Saved_Start_Time   = ''
  SELECT @Prev_Ps_Start_Time = ''
  SELECT @Prev_Ps_End_Time   = ''
  SELECT @Previous_Pu_Id     = -1
  SELECT @Previous_End_Time  = ''
  SELECT @Previous_Prod_Id   = -1
  SELECT @Previous_ApProd_Id = -1
  SELECT @Original_Found     = -1
  SELECT @Sum_Original_Found = 0
  SELECT @AP_Found 	      = -1
  SELECT @Sum_AP_Found       = 0
  SELECT @Fetch_Count        = 0
  SELECT @@Ps_Start_Time     = ''
  SELECT @@Ps_End_Time       = ''
  SELECT @@Start_Time        = ''
  SELECT @@End_Time          = ''
  SELECT @@Pu_Id             = -1
  SELECT @@Prod_Id           = -1
  SELECT @@Applied_Prod_Id   = -1
  OPEN TCursor
  --Tracking Product Events by counting successive applied events
  --(a) First loop: Save start time, store fetched variables in the "Previous" local variables
  --(a) Within same ID: 
  --    Switching occurs when Ps_Start_Time --> Ps_End_Time change.
  --    Switching occurs when previous running applied event(s) turn original, or previous running original event(s) 
  --    turn applied. When switching occurs, update the previous row with Saved start time, and mark "Keep": Update only if
  --    Prod_Id(original) or Applied_Prod_Id(applied) matches the filter.
  --(b) When product ID switch occurs: 
  --    Switching occurs when previous running original event(s) turn original, or previous running original event(s) turn
  --    applied, or previous running applied event(s) turn original, or previous running applied event(s) turn applied.
  --    When switching occurs, update the previous row with Saved start time, and mark "Keep": Update only if
  --    Prod_Id(original) or Applied_Prod_Id(applied) matches the filter.
TOP_OF_FETCH_LOOP:
  FETCH NEXT FROM TCursor INTO @@Pu_Id, @@Ps_Start_Time, @@Ps_End_Time, @@Start_Time, @@End_Time, @@Prod_Id, @@Applied_Prod_Id
  If (@@Fetch_Status = 0)
    BEGIN
      -- ********************************************************************************************
      -- FIRST FETCH: 
      If @Previous_Prod_Id = -1 	  	  	                 
        -- The very first fetch, collect row information and save start time
        BEGIN  
          --SELECT @Saved_Start_Time   = @@Start_Time
          SELECT @Previous_Pu_Id     = @@Pu_Id
          SELECT @Prev_Ps_Start_Time = @@Ps_Start_Time
          SELECT @Prev_Ps_End_Time   = @@Ps_End_Time
          SELECT @Previous_Prod_Id   = @@Prod_Id
          SELECT @Previous_End_Time  = @@End_Time
          SELECT @Previous_ApProd_Id = @@Applied_Prod_Id
          SELECT @AP_Found           = Case When @@Applied_Prod_Id Is NULL Then 0 Else 1 End
          SELECT @Original_Found     = 1 - @AP_Found
              --Accumulate fetched data
          SELECT @Sum_AP_Found 	      = @Sum_AP_Found + @AP_Found
          SELECT @Sum_Original_Found = @Sum_Original_Found + @Original_Found
          SELECT @Fetch_Count        = @Fetch_Count + 1
          --First Reel of a product uses start time from Production_Starts
          If @AP_Found = 1 --First reeel as applied product
            BEGIN
              If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @@Applied_Prod_Id)
                BEGIN
                  UPDATE #Applied_Products SET Start_Time = Ps_Start_Time WHERE Pu_Id = @@Pu_Id AND Prod_Id = @@Prod_Id AND End_Time = @@End_Time
                  SELECT @Saved_Start_Time = Ps_Start_Time FROM #Applied_Products WHERE Pu_Id = @@Pu_Id AND Prod_Id = @@Prod_Id AND End_Time = @@End_Time
                END
              --EndIf EXISTS
            END
          Else --1st Reel is original product
            BEGIN
             If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @@Prod_Id)
               BEGIN
                 UPDATE #Applied_Products SET Start_Time = Ps_Start_Time WHERE Pu_Id = @@Pu_Id AND Prod_Id = @@Prod_Id AND End_Time = @@End_Time
                 SELECT @Saved_Start_Time = Ps_Start_Time FROM #Applied_Products WHERE Pu_Id = @@Pu_Id AND Prod_Id = @@Prod_Id AND End_Time = @@End_Time
               END
             --EndIf EXISTS
            END
          --EndIf @AP_Found.
        END
      -- ********************************************************************************************
      -- PRODUCT ID SWITCHED OR PRODUCTION CHANGE OCCURS (SAME ID BUT DIFF START & END TIMES) 
         -- It is the time to 
         -- (a) process last events of previous product. Use Ps_End_Time for last reel)
         -- (b) Update start time for first reel (event) with Ps_Start_Time.
         --
      Else If @Previous_Prod_Id <> @@Prod_Id 
          OR ( @Previous_Prod_Id = @@Prod_Id AND @Prev_Ps_Start_Time <> @@Ps_Start_Time AND (@Prev_Ps_End_Time <> @@Ps_End_Time OR @Prev_Ps_End_Time Is NULL Or @@Ps_End_Time Is NULL) )
        BEGIN                    
          SELECT @AP_Found       = Case When @@Applied_Prod_Id Is NULL Then 0 Else 1 End
          SELECT @Original_Found = 1 - @AP_Found
          --Update Previous Running Events ...
          If @AP_Found = 1  --fetched event is applied
            BEGIN
              If @Sum_AP_Found = 0  --Running original turns applied
                BEGIN
                  --Update last row of running original
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_Prod_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1  
                       WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
                    END
                  --EndIf:EXISTS    
                END
              Else --(@Sum_AP_Found >0): Running applied turns applied at new ID
                BEGIN
                  --Update last row of running applied (if Applied_Prod_Id matches filter)
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_ApProd_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time                     
                      SELECT @Sum_AP_Found = 0 --reset applied running count
                    END
                  --EndIf:EXISTS
                END
              --EndIf:@Sum_AP_Found =0
            END
          Else  --@AP_Found = 0: Original fetched
            BEGIN
              If @Sum_AP_Found > 0  --Running applied switches to original
                BEGIN                  
                  --Update last row in running AP events (if Applied_Prod_Id matches filter), and reset the running sum
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_ApProd_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1 
                       WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
                    END
                  --EndIf:EXISTS
                  SELECT @Sum_AP_Found = 0  --(reset running sum)                                    
                END
              Else --(@Sum_AP_Found = 0): Running original turns original at ID switch
                BEGIN
                  --Update last row in running original events
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_Prod_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1 
                       WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time        
                    END
                  --EndIf:EXISTS
                END
              --EndIf:@Sum_AP_Found >0
            END           
          --EndIf:@AP_Found =1 Block
              --Reset counters (for original product only tracking)
          SELECT @Fetch_Count        = 0
          SELECT @Sum_Original_Found = 0
              --Collect relevant info for this ID ....
          SELECT @Previous_Pu_Id     = @@Pu_Id
          SELECT @Prev_Ps_Start_Time = @@Ps_Start_Time
          SELECT @Prev_Ps_End_Time   = @@Ps_End_Time
          SELECT @Previous_Prod_Id   = @@Prod_Id
          SELECT @Previous_End_Time  = @@End_Time
          SELECT @Previous_ApProd_Id = @@Applied_Prod_Id
              --Accumulate fetched data
          SELECT @Sum_AP_Found 	      = @Sum_AP_Found + @AP_Found
          SELECT @Sum_Original_Found = @Sum_Original_Found + @Original_Found
          SELECT @Fetch_Count        = @Fetch_Count + 1
          --First Reel of product uses start time from Production_Starts
          SELECT @Saved_Start_Time = Ps_Start_Time  FROM #Applied_Products WHERE Pu_Id = @@Pu_Id AND Prod_Id = @@Prod_Id AND End_Time = @@End_Time
        END
      -- ********************************************************************************************
      -- RUNNING PRODUCT -- SAME PRODUCT FETCHED; Has this event been applied?
      Else If @Previous_Prod_Id = @@Prod_Id              
        BEGIN  
          --Get applied/original status
          SELECT @AP_Found       = Case When @@Applied_Prod_Id Is NULL Then 0 Else 1 End
          SELECT @Original_Found = 1 - @AP_Found
          If @AP_Found = 1 --fetched event is applied
            BEGIN
              If @Sum_AP_Found = 0 --Running original switches to applied
                BEGIN
                  --Update last row of running original
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_Prod_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, Keep_Event = 1 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
                    END
                  --EndIf:EXISTS
                  SELECT @Saved_Start_Time = @@Start_Time --Save start_time
                END
              --EndIf:@Sum_AP_Found =0
            END     
          Else  --(@AP_Found = 0): fetched event is original
            BEGIN
              If @Sum_AP_Found > 0  --Running applied turns original
                BEGIN                  
                  --Update last row in running AP events (if Applied_Prod_Id matches filter), and reset the running sum
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_ApProd_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, Keep_Event = 1 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
                    END
                  --EndIf                      
                  SELECT @Sum_AP_Found = 0  --(reset running sum)                                    
                  SELECT @Saved_Start_Time = @@Start_Time  --Save current original event's Start_Time
                END
              --Else --(@Sum_AP_Found = 0): Running original turns original turns original
                     --(do nothing, just continue accumulate running events)
              --EndIf:@Sum_AP_Found >0
            END           
          --EndIf:@AP_Found =1 Block
              --Collect information of current fetched
          SELECT @Previous_Pu_Id     = @@Pu_Id
          SELECT @Prev_Ps_Start_Time = @@Ps_Start_Time
          SELECT @Prev_Ps_End_Time   = @@Ps_End_Time
          SELECT @Previous_Prod_Id   = @@Prod_Id
          SELECT @Previous_End_Time  = @@End_Time
          SELECT @Previous_ApProd_Id = @@Applied_Prod_Id
              --Accumulate fetched data
          SELECT @Sum_AP_Found 	      = @Sum_AP_Found + @AP_Found
          SELECT @Sum_Original_Found = @Sum_Original_Found + @Original_Found
          SELECT @Fetch_Count        = @Fetch_Count + 1
        END
      --EndIf:@Previous_Prod_Id = -1( Main block )
      GOTO TOP_OF_FETCH_LOOP
    END
  --EndIf (@@Fetch_Status = 0)
  -- ****************************************************************
  --HANDLE END OF LOOP UPDATE: ( single event also included here )
    If @AP_Found = 1  --Last fetch was applied
      BEGIN
        --Handle previously 100% running applied
        If @Fetch_Count = @Sum_AP_Found 
          BEGIN
            If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_ApProd_Id )
              BEGIN
                UPDATE #Applied_Products SET Start_Time = Ps_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1
                 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
              END
          END        
        Else --Not 100% running applied
            If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_ApProd_Id )
              BEGIN
               UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1 
                WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
              END
            --EndIf:EXISTS
        --EndIf @Fetch_Count
      END
    Else --Last fetch was original (@AP_Found =0)
      BEGIN
        --Handle previously 100% Running original events, use times from production_Starts table
        If @Fetch_Count = @Sum_Original_Found
          BEGIN
            If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_Prod_Id )
              BEGIN
                UPDATE #Applied_Products SET Start_Time = Ps_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1
                 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
              END
          END     
        Else --not 100% running original event; use times from Events table
          BEGIN
            If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_Prod_Id )
              BEGIN
                UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1 
                 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
              END
            --EndIf:EXISTS
          END
        --EndIf:@Fetch_Count = @Sum_Original_Found
      END
    --EndIf:@Sum_AP_Found =1
  CLOSE TCursor
  DEALLOCATE TCursor
  -- DELETE UNMARKED ROWS .....
  DELETE FROM #Applied_Products WHERE Keep_Event Is NULL
  -- Insert The Detail Records We Care About Into #TempUDE Temp Table
  --
  If      @CrewShift = @NoCrewNoShift   GOTO NOCREW_NOSHIFT_APPLIED_INSERT
  Else If @CrewShift = @HasCrewNoShift  GOTO HASCREW_NOSHIFT_APPLIED_INSERT
  Else If @CrewShift = @NoCrewHasShift  GOTO NOCREW_HASSHIFT_APPLIED_INSERT
  Else                                  GOTO HASCREW_HASSHIFT_APPLIED_INSERT
  --EndIf:Crew,shift
NOCREW_NOSHIFT_APPLIED_INSERT:
  If @PU_Id Is NULL
    If @Ack_Required = 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Ack_On, Ack_By, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                     When ap.End_Time Is NULL Then D.End_Time
                                     When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ap.Prod_Id, ap.Applied_Prod_Id, D.Ack_On, D.Ack_By, D.Research_User_Id, D.Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id
             AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
        END
    Else --@Ack_Required > 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Ack_On, Ack_By, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                     When ap.End_Time Is NULL Then D.End_Time
                                     When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ap.Prod_Id, ap.Applied_Prod_Id, D.Ack_On, D.Ack_By, D.Research_User_Id, D.Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id
             AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.Ack = 1
        END
    --EndIf:@Ack_Required...
  Else    --@PU_Id NOT NULL
    If @Ack_Required = 0 
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Ack_On, Ack_By, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                     When ap.End_Time Is NULL Then D.End_Time
                                     When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ap.Prod_Id, ap.Applied_Prod_Id, D.Ack_On, D.Ack_By, D.Research_User_Id, D.Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id
             AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.PU_Id = @PU_Id 
      END
    Else --@Ack_Required > 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Ack_On, Ack_By, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                     When ap.End_Time Is NULL Then D.End_Time
                                     When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ap.Prod_Id, ap.Applied_Prod_Id, D.Ack_On, D.Ack_By, D.Research_User_Id, D.Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id
             AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.PU_Id = @PU_Id AND D.Ack = 1
      END
    --EndIf:@Ack_Required...
  --EndIf @PU_Id
  GOTO CONTINUE_UDE_PROCESS
HASCREW_NOSHIFT_APPLIED_INSERT:
  If @PU_Id Is NULL
    If @Ack_Required = 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Ack_On, Ack_By, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                     When ap.End_Time Is NULL Then D.End_Time
                                     When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ap.Prod_Id, ap.Applied_Prod_Id, D.Ack_On, D.Ack_By, D.Research_User_Id, D.Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time) 
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
        END
    Else --@Ack_Required > 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Ack_On, Ack_By, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                     When ap.End_Time Is NULL Then D.End_Time
                                     When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ap.Prod_Id, ap.Applied_Prod_Id, D.Ack_On, D.Ack_By, D.Research_User_Id, D.Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time) 
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.Ack = 1
        END
    --EndIf:@Ack_Required...
  Else    --@PU_Id NOT NULL
    If @Ack_Required = 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Ack_On, Ack_By, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                     When ap.End_Time Is NULL Then D.End_Time
                                     When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ap.Prod_Id, ap.Applied_Prod_Id, D.Ack_On, D.Ack_By, D.Research_User_Id, D.Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id
             AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time) AND C.PU_Id = @PU_Id 
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.PU_Id = @PU_Id 
      END
    Else --@Ack_Required > 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Ack_On, Ack_By, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                     When ap.End_Time Is NULL Then D.End_Time
                                     When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ap.Prod_Id, ap.Applied_Prod_Id, D.Ack_On, D.Ack_By, D.Research_User_Id, D.Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id
             AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time) AND C.PU_Id = @PU_Id 
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.PU_Id = @PU_Id AND D.Ack = 1
      END
    --EndIf:@Ack_Required...
  --EndIf @PU_Id
  GOTO CONTINUE_UDE_PROCESS
NOCREW_HASSHIFT_APPLIED_INSERT:
  If @PU_Id Is NULL
    If @Ack_Required = 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Ack_On, Ack_By, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                     When ap.End_Time Is NULL Then D.End_Time
                                     When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ap.Prod_Id, ap.Applied_Prod_Id, D.Ack_On, D.Ack_By, D.Research_User_Id, D.Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
        END
    Else --@Ack_Required >0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Ack_On, Ack_By, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                     When ap.End_Time Is NULL Then D.End_Time
                                     When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ap.Prod_Id, ap.Applied_Prod_Id, D.Ack_On, D.Ack_By, D.Research_User_Id, D.Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.Ack = 1
        END
    --EndIf:@Ack_Required...
  Else    --@PU_Id NOT NULL
    If @Ack_Required = 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Ack_On, Ack_By, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                     When ap.End_Time Is NULL Then D.End_Time
                                     When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ap.Prod_Id, ap.Applied_Prod_Id, D.Ack_On, D.Ack_By, D.Research_User_Id, D.Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id
             AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc
             AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time) AND C.PU_Id = @PU_Id
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.PU_Id = @PU_Id 
      END
    Else --@Ack_Required > 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Ack_On, Ack_By, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                     When ap.End_Time Is NULL Then D.End_Time
                                     When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ap.Prod_Id, ap.Applied_Prod_Id, D.Ack_On, D.Ack_By, D.Research_User_Id, D.Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id
             AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc
             AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time) AND C.PU_Id = @PU_Id
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.PU_Id = @PU_Id AND D.Ack = 1
      END
    --EndIf:@Ack_Required...
  --EndIf @PU_Id
  GOTO CONTINUE_UDE_PROCESS
HASCREW_HASSHIFT_APPLIED_INSERT:
  If @PU_Id Is NULL
    If @Ack_Required = 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Ack_On, Ack_By, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                     When ap.End_Time Is NULL Then D.End_Time
                                     When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ap.Prod_Id, ap.Applied_Prod_Id, D.Ack_On, D.Ack_By, D.Research_User_Id, D.Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time) 
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
        END
    Else --@Ack_Required > 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Ack_On, Ack_By, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                     When ap.End_Time Is NULL Then D.End_Time
                                     When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ap.Prod_Id, ap.Applied_Prod_Id, D.Ack_On, D.Ack_By, D.Research_User_Id, D.Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time) 
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.Ack = 1
        END
    --EndIf:@Ack_Required...
  Else    --@PU_Id NOT NULL
    If @Ack_Required = 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Ack_On, Ack_By, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                     When ap.End_Time Is NULL Then D.End_Time
                                     When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ap.Prod_Id, ap.Applied_Prod_Id, D.Ack_On, D.Ack_By, D.Research_User_Id, D.Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id
             AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
             AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time) AND C.PU_Id = @PU_Id  
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.PU_Id = @PU_Id 
      END
    Else --@Ack_Required > 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, PU_Id, Event_Subtype_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Ack_On, Ack_By, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT D.UDE_Id, D.UDE_Desc
               , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                     When ap.End_Time Is NULL Then D.End_Time
                                     When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
               , D.Duration, D.PU_Id, D.Event_Subtype_Id, D.Cause1, D.Cause2, D.Cause3, D.Cause4, D.Action1, D.Action2, D.Action3, D.Action4, ap.Prod_Id, ap.Applied_Prod_Id, D.Ack_On, D.Ack_By, D.Research_User_Id, D.Research_Status_Id, D.Modified_On, D.Research_Open_Date, D.Research_Close_Date, D.Comment_Id, D.Cause_Comment_Id, D.Action_Comment_Id, D.Research_Comment_Id
            FROM User_Defined_Events D
            JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id
             AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
             AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time) AND C.PU_Id = @PU_Id  
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL ) AND D.PU_Id = @PU_Id AND D.Ack = 1
      END
    --EndIf:@Ack_Required...
  --EndIf @PU_Id
  GOTO CONTINUE_UDE_PROCESS
CONTINUE_UDE_PROCESS:
  -- Clean up unwanted PU_Id = 0 (marked for unused/obsolete)
  DELETE FROM #TempUDE WHERE PU_Id = 0 OR Event_Subtype_Id = 0
  --Delete Rows that don't match selected PU_Id or Event_Subtype_Id, reasons, etc.
  If @PU_Id Is NOT NULL            DELETE FROM #TempUDE WHERE PU_Id Is NULL OR PU_Id <> @PU_Id
  If @Event_Subtype_Id Is NOT NULL DELETE FROM #TempUDE WHERE Event_Subtype_Id Is NULL OR Event_Subtype_Id <> @Event_Subtype_Id
  If @SelectR1 Is NOT NULL         DELETE FROM #TempUDE WHERE R1_Id Is NULL Or R1_Id <> @SelectR1
  If @SelectR2 Is NOT NULL         DELETE FROM #TempUDE WHERE R2_Id Is NULL Or R2_Id <> @SelectR2
  If @SelectR3 Is NOT NULL         DELETE FROM #TempUDE WHERE R3_Id Is NULL Or R3_Id <> @SelectR3
  If @SelectR4 Is NOT NULL         DELETE FROM #TempUDE WHERE R4_Id Is NULL Or R4_Id <> @SelectR4
  If @SelectA1 Is NOT NULL         DELETE FROM #TempUDE WHERE A1_Id Is NULL OR A1_Id <> @SelectA1
  If @SelectA2 Is NOT NULL         DELETE FROM #TempUDE WHERE A2_Id Is NULL OR A2_Id <> @SelectA2
  If @SelectA3 Is NOT NULL         DELETE FROM #TempUDE WHERE A3_Id Is NULL OR A3_Id <> @SelectA3
  If @SelectA4 Is NOT NULL         DELETE FROM #TempUDE WHERE A4_Id Is NULL OR A4_Id <> @SelectA4
  -- Update Temp Table #TempUDE: Take Care Of Record Start, End Times, and Duration
  UPDATE #TempUDE SET Start_Time = @Start_Time WHERE Start_Time < @Start_Time
  UPDATE #TempUDE SET End_Time = @End_Time WHERE End_Time > @End_Time OR End_Time is NULL
  UPDATE #TempUDE SET Duration = DATEDIFF(ss, Start_Time, End_Time) / 60.0
/*
 	  	 Non Productive Time
 	  	 TODO: Copy the below lines to a new sp so that we can just call that new sp
*/
DECLARE @Periods_NPT TABLE ( PeriodId int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,StartTime Datetime, EndTime Datetime,NPDuration int)
      INSERT INTO @Periods_NPT ( Starttime,Endtime)
      SELECT      
                  StartTime               = CASE      WHEN np.Start_Time < @Start_Time THEN @Start_Time
                                                ELSE np.Start_Time
                                                END,
                  EndTime           = CASE      WHEN np.End_Time > @End_time THEN @End_time
                                                ELSE np.End_Time
                                                END
      FROM dbo.NonProductive_Detail np WITH (NOLOCK)
            JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON      ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
                                                                                                      AND ercd.ERC_Id = (SELECT Non_Productive_Category FROM prod_units where PU_id =@PU_Id)
      WHERE PU_Id = @PU_id
                  AND np.Start_Time < @End_time
                  AND np.End_Time > @Start_Time
-------NPT OF Downtime-------
-- Case 1 :  Downtime    St---------------------End
-- 	  	  	  NPT   St--------------End
UPDATE #TempUDE SET Start_Time = n.Endtime,
 	  	  	  	  	 NPT = 1
FROM #TempUDE  JOIN @Periods_NPT n ON (Start_Time > n.StartTime AND End_time > n.EndTime AND Start_Time < n.EndTime)
-- Case 2 :  Downtime    St---------------------End
-- 	  	  	  NPT 	  	  	  	  	 St--------------End
UPDATE #TempUDE SET End_Time = n.Starttime,
 	  	  	  	    NPT = 1
FROM 	 #TempUDE 	  	    
JOIN @Periods_NPT n ON (Start_Time < n.StartTime AND End_Time < n.Endtime AND End_Time > n.StartTime)
 	  	 
-- Case 3 :  Downtime   St-----------------------End
-- 	  	  	  NPT   St-------------------------------End
UPDATE #TempUDE SET Start_Time = End_Time,
 	  	  	  	  	 NPT = 1
FROM 	 #TempUDE  	  	    
JOIN @Periods_NPT n ON( (Start_Time BETWEEN n.StartTime AND n.EndTime) AND (End_time BETWEEN n.StartTime AND n.EndTime))
Update #TempUDE Set Duration =DateDiff(ss,Start_Time,End_Time)/60.0
-- Case 4 :  Downtime   St-----------------------End
-- 	  	  	  NPT 	  	    St-----------------End
UPDATE #TempUDE  SET NPT = 1
FROM #TempUDE  JOIN @Periods_NPT n ON( (n.StartTime BETWEEN Start_Time AND End_Time) AND (n.Endtime BETWEEN Start_Time AND End_Time))    
-- --------------------------------------------------
  -- Retrieve RecordSet based ON passed in paramters
  --
  If @TimeSort = 1
    BEGIN
        SELECT D.UDE_Id
             , D.UDE_Desc
             , D.Duration
             , Start_Time = Case When D.Crew_Start Is NULL Then D.Start_Time
                                 When D.Start_Time <= D.Crew_Start Then D.Crew_Start Else D.Start_Time End
             , End_Time   = Case When D.Crew_End Is NULL Then D.End_Time
                                 When D.End_Time >= D.Crew_End Then D.Crew_End Else D.End_Time End
             , P.Prod_Code
             , [Applied_Prod_Code] = p2.Prod_Code
             , [Location]         = Case When D.PU_Id Is NULL              Then @Unspecified  Else PU.PU_Desc End
             , [Event_Subtype]    = Case When D.Event_Subtype_Id Is NULL   Then @Unspecified  Else es.Event_Subtype_Desc End
             , Reason1            = Case When D.R1_Id Is NULL              Then @Unspecified  Else R1.Event_Reason_Name End
             , Reason2            = Case When D.R2_Id Is NULL              Then @Unspecified  Else R2.Event_Reason_Name End
             , Reason3            = Case When D.R3_Id Is NULL              Then @Unspecified  Else R3.Event_Reason_Name End
             , Reason4 	           = Case When D.R4_Id Is NULL              Then @Unspecified  Else R4.Event_Reason_Name End
             , Action1            = Case When D.A1_Id Is NULL              Then @Unspecified  Else A1.Event_Reason_Name End
             , Action2            = Case When D.A2_Id Is NULL              Then @Unspecified  Else A2.Event_Reason_Name End
             , Action3            = Case When D.A3_Id Is NULL              Then @Unspecified  Else A3.Event_Reason_Name End
             , Action4            = Case When D.A4_Id Is NULL              Then @Unspecified  Else A4.Event_Reason_Name End
             , [Reasearch_Status] = Case When D.Research_Status_Id Is NULL Then @Unspecified  Else r.Research_Status_Desc End
             , D.Crew_Desc
             , D.Shift_Desc
             , [Ack_By_User] = usr.Username
             , Ack_On
             , [Research_User] = usr2.Username
             , D.Modified_On
             , D.Research_Open_Date
             , D.Research_Close_Date
             , D.Comment_Id
             , D.Cause_Comment_Id
             , D.Action_Comment_Id
             , D.Research_Comment_Id
          FROM #TempUDE D
          JOIN Prod_Units PU ON PU.PU_Id = D.PU_Id
          JOIN Products P ON P.Prod_Id = D.Prod_Id
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = D.Applied_Prod_Id
          LEFT OUTER JOIN Event_Subtypes es ON es.Event_Subtype_Id = D.Event_Subtype_Id
          LEFT OUTER JOIN Users usr ON usr.User_Id = D.Ack_By
          LEFT OUTER JOIN Users usr2 ON usr2.User_Id = D.Research_User_Id
          LEFT OUTER JOIN Event_Reasons R1 ON D.R1_Id = R1.Event_Reason_Id
          LEFT OUTER JOIN Event_Reasons R2 ON D.R2_Id = R2.Event_Reason_Id
          LEFT OUTER JOIN Event_Reasons R3 ON D.R3_Id = R3.Event_Reason_Id
          LEFT OUTER JOIN Event_Reasons R4 ON D.R4_Id = R4.Event_Reason_Id
          LEFT OUTER JOIN Event_Reasons A1 ON D.A1_Id = A1.Event_Reason_Id
          LEFT OUTER JOIN Event_Reasons A2 ON D.A2_Id = A2.Event_Reason_Id
          LEFT OUTER JOIN Event_Reasons A3 ON D.A3_Id = A3.Event_Reason_Id
          LEFT OUTER JOIN Event_Reasons A4 ON D.A4_Id = A4.Event_Reason_Id
          LEFT OUTER JOIN Research_Status r ON r.Research_Status_Id = D.Research_Status_Id
 	  	   WHERE D.NPT IS NULL 	 
      ORDER BY D.Start_Time ASC
    END
  Else    --Desceding sort
    BEGIN
        SELECT D.UDE_Id
             , D.UDE_Desc
             , D.Duration
             , Start_Time = Case When D.Crew_Start Is NULL Then D.Start_Time
                                 When D.Start_Time <= D.Crew_Start Then D.Crew_Start Else D.Start_Time End
             , End_Time   = Case When D.Crew_End Is NULL Then D.End_Time
                                 When D.End_Time >= D.Crew_End Then D.Crew_End Else D.End_Time End
             , P.Prod_Code
             , [Applied_Prod_Code] = p2.Prod_Code
             , [Location]         = Case When D.PU_Id Is NULL              Then @Unspecified  Else PU.PU_Desc End
             , [Event_Subtype]    = Case When D.Event_Subtype_Id Is NULL   Then @Unspecified  Else es.Event_Subtype_Desc End
             , Reason1            = Case When D.R1_Id Is NULL              Then @Unspecified  Else R1.Event_Reason_Name End
             , Reason2            = Case When D.R2_Id Is NULL              Then @Unspecified  Else R2.Event_Reason_Name End
             , Reason3            = Case When D.R3_Id Is NULL              Then @Unspecified  Else R3.Event_Reason_Name End
             , Reason4 	           = Case When D.R4_Id Is NULL              Then @Unspecified  Else R4.Event_Reason_Name End
             , Action1            = Case When D.A1_Id Is NULL              Then @Unspecified  Else A1.Event_Reason_Name End
             , Action2            = Case When D.A2_Id Is NULL              Then @Unspecified  Else A2.Event_Reason_Name End
             , Action3            = Case When D.A3_Id Is NULL              Then @Unspecified  Else A3.Event_Reason_Name End
             , Action4            = Case When D.A4_Id Is NULL              Then @Unspecified  Else A4.Event_Reason_Name End
             , [Reasearch_Status] = Case When D.Research_Status_Id Is NULL Then @Unspecified  Else r.Research_Status_Desc End
             , D.Crew_Desc
             , D.Shift_Desc
             , [Ack_By_User] = usr.Username
             , Ack_On
             , [Research_User] = usr2.Username
             , D.Modified_On
             , D.Research_Open_Date
             , D.Research_Close_Date
             , D.Comment_Id
             , D.Cause_Comment_Id
             , D.Action_Comment_Id
             , D.Research_Comment_Id
          FROM #TempUDE D
          JOIN Prod_Units PU ON PU.PU_Id = D.PU_Id
          JOIN Products P ON P.Prod_Id = D.Prod_Id
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = D.Applied_Prod_Id
          LEFT OUTER JOIN Event_Subtypes es ON es.Event_Subtype_Id = D.Event_Subtype_Id
          LEFT OUTER JOIN Users usr ON usr.User_Id = D.Ack_By
          LEFT OUTER JOIN Users usr2 ON usr2.User_Id = D.Research_User_Id
          LEFT OUTER JOIN Event_Reasons R1 ON D.R1_Id = R1.Event_Reason_Id
          LEFT OUTER JOIN Event_Reasons R2 ON D.R2_Id = R2.Event_Reason_Id
          LEFT OUTER JOIN Event_Reasons R3 ON D.R3_Id = R3.Event_Reason_Id
          LEFT OUTER JOIN Event_Reasons R4 ON D.R4_Id = R4.Event_Reason_Id
          LEFT OUTER JOIN Event_Reasons A1 ON D.A1_Id = A1.Event_Reason_Id
          LEFT OUTER JOIN Event_Reasons A2 ON D.A2_Id = A2.Event_Reason_Id
          LEFT OUTER JOIN Event_Reasons A3 ON D.A3_Id = A3.Event_Reason_Id
          LEFT OUTER JOIN Event_Reasons A4 ON D.A4_Id = A4.Event_Reason_Id
          LEFT OUTER JOIN Research_Status r ON r.Research_Status_Id = D.Research_Status_Id
 	  	   WHERE D.NPT IS NULL 	 
      ORDER BY D.Start_Time DESC
    END
  --EndIf @TimeSort...
  GOTO DROP_TEMP_TABLES
DROP_TEMP_TABLES:
  DROP TABLE #TempUDE
  DROP TABLE #Products
  DROP TABLE #Prod_Starts
  DROP TABLE #Applied_Products
--
--DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId

CREATE PROCEDURE dbo.[spXLA_AlarmDetails_Bak_177]
 	   @Var_Id 	  	 Int
 	 , @Start_Time 	  	 DateTime
 	 , @End_Time 	  	 DateTime
 	 , @Acknowledged 	  	 TinyInt = 0
 	 , @SelectR1 	  	 Int
 	 , @SelectR2 	  	 Int
 	 , @SelectR3 	  	 Int
 	 , @SelectR4 	  	 Int
 	 , @Prod_Id 	  	 Int = NULL 
 	 , @Group_Id 	  	 Int = NULL
 	 , @Prop_Id 	  	 Int = NULL
 	 , @Char_Id 	  	 Int = NULL
 	 , @ProductSpecified 	 TinyInt = 0
 	 , @TimeSort 	  	 TinyInt = NULL
 	 , @Username Varchar(50) = NULL
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
DECLARE @QueryType  	 tinyInt
DECLARE @MasterUnit  	 Int
DECLARE @UserId 	 Int
DECLARE @Unspecified varchar(50)
SELECT @UserId = User_Id
FROM users
WHERE Username = @Username
EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
SELECT @Unspecified = dbo.fnDBTranslate(@Langid, 38333, 'Unspecified')
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,@InTimeZone)
SELECT @MasterUnit = v.PU_Id FROM Variables v WHERE v.Var_Id = @Var_Id
-- Get All TED Records In Desired Fields
CREATE TABLE #TopNDR (
 	   Alarm_Id 	 Int
 	 , Alarm_Desc 	 Varchar(1000) NULL
 	 , Start_Time 	 DateTime
 	 , End_Time 	 DateTime    NULL
  	 , Duration 	 real        NULL
 	 , Source_Pu_Id 	 Int         NULL
 	 , Prod_Id 	 Int         NULL
 	 , Reason1_Id 	 Int         NULL
 	 , Reason2_Id 	 Int         NULL 
 	 , Reason3_Id  	 Int         NULL
 	 , Reason4_Id  	 Int         NULL
 	 , Comment_Id 	 Int         NULL
 	 )
--If Caller doesn't specify a product (or product Info), they don't care which products alarms are connected to, 
--so we skip joining production_starts, and get data based on start & end times from Alarms table, product will be null. 
If @ProductSpecified = 1
    BEGIN
 	 CREATE TABLE #Prod_Starts (PU_Id Int, Prod_Id Int, Start_Time DateTime, End_Time DateTime NULL)
 	 --Figure Out Query Type Based On Supplied Product Information
 	 If @Prod_Id Is NOT NULL SELECT @QueryType = 1   	  	  	  	  	 --Single Product
 	 Else If @Group_Id Is NOT NULL AND @Prop_Id Is NULL SELECT @QueryType = 2   	 --Single Group
 	 Else If @Prop_Id Is NOT NULL AND @Group_Id Is NULL SELECT @QueryType = 3   	 --Single Characteristic
 	 Else If @Prop_Id Is NOT NULL AND @Group_Id Is NOT NULL SELECT @QueryType = 4   	 --Group and Property  
 	 
 	 If @QueryType = 1 	  	  	 --Single Product
     	     BEGIN
                INSERT INTO #Prod_Starts
                     SELECT  ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
                       FROM  Production_Starts ps
                      WHERE  (ps.PU_Id = @MasterUnit AND  ps.PU_Id <> 0)
 	                 AND  Prod_Id = @Prod_Id 
 	                 AND  ( 	  (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	  	                OR (End_Time BETWEEN @Start_Time AND @End_Time) 
 	  	                OR (Start_Time <= @Start_Time AND ((End_Time > @End_Time) OR (End_Time Is NULL)))
                             )
 	     END
 	 Else 	  	  	  	  	 --Not a single product 
            BEGIN
         	 CREATE TABLE #Products (Prod_Id Int)
         	 If @QueryType = 2  	  	  	 --Product Group
             	     BEGIN
                        INSERT INTO #Products
                        SELECT Prod_Id  FROM Product_Group_Data  WHERE Product_Grp_Id = @Group_Id
             	     END
                Else If @QueryType = 3 	  	 --Characteristic
                    BEGIN
                        INSERT INTO #Products
                        SELECT DISTINCT Prod_Id  FROM Pu_Characteristics WHERE Prop_Id = @Prop_Id AND Char_Id = @Char_Id
                    END
 	  	 Else 	  	  	  	 --Group and Property  
             	     BEGIN
                 	 INSERT INTO #Products
                 	 SELECT Prod_Id  FROM Product_Group_Data WHERE Product_Grp_Id = @Group_Id
 	                 INSERT INTO #Products
 	                 SELECT DISTINCT Prod_Id FROM Pu_Characteristics  WHERE Prop_Id = @Prop_Id AND Char_Id = @Char_Id
             	     END
 	  	 --EndIf @QueryType = 2
            END
        --EndIf Single Product
        BEGIN
 	     INSERT INTO #Prod_Starts
                 SELECT  ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
                   FROM  Production_Starts ps
                   JOIN  #Products p ON ps.Prod_Id = p.Prod_Id 
                  WHERE  (ps.PU_Id = @MasterUnit AND  ps.PU_Id <> 0)
 	             AND  (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	  	            OR (End_Time BETWEEN @Start_Time AND @End_Time) 
 	  	            OR (Start_Time <= @Start_Time AND ((End_Time > @End_Time) OR (End_Time Is NULL)))
                         )
        END
        DROP TABLE #Products
 	 --Fill In TopNDR Table
 	 If @Acknowledged = 1 
            BEGIN
 	         INSERT INTO #TopNDR (Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id, Comment_Id)
                     SELECT  A.Alarm_Id, A.Alarm_Desc, A.Start_Time, A.End_Time, A.Duration, A.Source_PU_Id, PS.Prod_Id, A.Cause1, A.Cause2, A.Cause3, A.Cause4, A.Cause_Comment_Id
                       FROM  Alarms A
                       JOIN  #Prod_Starts PS ON (PS.Start_Time <= A.Start_Time AND (PS.End_Time > A.Start_Time OR PS.End_Time Is NULL))
                       JOIN  Alarm_Template_Var_Data T ON T.ATD_Id = A.ATD_Id AND T.Var_Id = @Var_Id
                      WHERE  A.Alarm_Type_Id = 1 	 --Variable-type Alarms 
 	                 AND  A.Ack = 1
 	                 AND  (    (A.Start_Time >= @Start_Time AND A.Start_Time < @End_Time) 	  	  	    --Alarm starts Within timeRange
 	  	                OR (A.End_Time > @Start_Time AND A.End_Time <= @End_Time)  	  	  	    --Alarm ends within timeRange
 	  	                OR (A.Start_Time < @Start_Time AND A.End_Time > @End_Time AND A.End_Time Is NOT NULL) --Alarm starts before timeRange and ends after timeRange
 	  	                OR (A.Start_Time < @Start_Time AND A.End_Time Is NULL) 	  	  	  	    --Alarm starts before timeRange and hasn't ended yet
 	  	              )
            END
        Else --@Acknowledged = 0
            BEGIN
 	         INSERT INTO #TopNDR (Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id, Comment_Id)
                     SELECT  A.Alarm_Id, A.Alarm_Desc, A.Start_Time, A.End_Time, A.Duration, A.Source_PU_Id, PS.Prod_Id, A.Cause1, A.Cause2, A.Cause3, A.Cause4, A.Cause_Comment_Id
                       FROM  Alarms A
                       JOIN  #Prod_Starts PS ON (PS.Start_Time <= A.Start_Time AND (PS.End_Time > A.Start_Time OR PS.End_Time Is NULL))
                       JOIN  Alarm_Template_Var_Data T ON T.ATD_Id = A.ATD_Id AND T.Var_Id = @Var_Id
                      WHERE  A.Alarm_Type_Id = 1 	 --Variable-type Alarms 
 	                 AND  (    (A.Start_Time >= @Start_Time AND A.Start_Time < @End_Time) 	  	  	    --Alarm starts Within timeRange
 	  	                OR (A.End_Time > @Start_Time AND A.End_Time <= @End_Time)  	  	  	    --Alarm ends within timeRange
 	  	                OR (A.Start_Time < @Start_Time AND A.End_Time > @End_Time AND A.End_Time Is NOT NULL) --Alarm starts before timeRange and ends after timeRange
 	  	                OR (A.Start_Time < @Start_Time AND A.End_Time Is NULL) 	  	  	  	    --Alarm starts before timeRange and hasn't ended yet
 	  	              )
            END
        --EndIf @Acknowledged ..
 	 -- Clean up unwanted PU_Id = 0 (0 means they are marked for unused/obsolete)
 	 DELETE FROM #TopNDR WHERE Source_Pu_Id = 0
 	 DROP TABLE #Prod_Starts
    END
Else --When Product Not specified, we have simpler query...
    BEGIN
    -- Get All The Detail Records We Care About
    -- Insert Data Into #TopNDR Temp Table
        If @Acknowledged = 1 --must get acknowledged rows only
            BEGIN
 	         INSERT INTO #TopNDR (Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id, Comment_Id)
                     SELECT  A.Alarm_Id, A.Alarm_Desc, A.Start_Time, A.End_Time, A.Duration, A.Source_PU_Id, A.Cause1, A.Cause2, A.Cause3, A.Cause4, A.Cause_Comment_Id
                       FROM  Alarms A
                       JOIN  Alarm_Template_Var_Data T ON T.ATD_Id = A.ATD_Id AND T.Var_Id = @Var_Id
                      WHERE  A.Alarm_Type_Id = 1 	 --Variable-type Alarms 
 	                 AND  A.Ack = 1
 	                 AND  (    (A.Start_Time >= @Start_Time AND A.Start_Time < @End_Time) 	  	  	    --Alarm starts Within timeRange
 	  	                OR (A.End_Time > @Start_Time AND A.End_Time <= @End_Time)  	  	  	    --Alarm ends within timeRange
 	  	                OR (A.Start_Time < @Start_Time AND A.End_Time > @End_Time AND A.End_Time Is NOT NULL) --Alarm starts before timeRange and ends after timeRange
 	  	                OR (A.Start_Time < @Start_Time AND A.End_Time Is NULL) 	  	  	  	    --Alarm starts before timeRange and hasn't ended yet
 	      	              )
            END
        Else --any rows regardless of Acknowledge status
            BEGIN
 	         INSERT INTO #TopNDR (Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id, Comment_Id)
                     SELECT  A.Alarm_Id, A.Alarm_Desc, A.Start_Time, A.End_Time, A.Duration, A.Source_PU_Id, A.Cause1, A.Cause2, A.Cause3, A.Cause4, A.Cause_Comment_Id
                       FROM  Alarms A
                       JOIN  Alarm_Template_Var_Data T ON T.ATD_Id = A.ATD_Id AND T.Var_Id = @Var_Id
                      WHERE  A.Alarm_Type_Id = 1 	 --Variable-type Alarms 
 	                 AND  (    (A.Start_Time >= @Start_Time AND A.Start_Time < @End_Time) 	  	  	    --Alarm starts Within timeRange
 	  	                OR (A.End_Time > @Start_Time AND A.End_Time <= @End_Time)  	  	  	    --Alarm ends within timeRange
 	  	                OR (A.Start_Time < @Start_Time AND A.End_Time > @End_Time AND A.End_Time Is NOT NULL) --Alarm starts before timeRange and ends after timeRange
 	  	                OR (A.Start_Time < @Start_Time AND A.End_Time Is NULL) 	  	  	  	    --Alarm starts before timeRange and hasn't ended yet
 	  	              )
            END
        --EndIf @Acknowledged ..
    END
--EndIf @ProductSpecified = 1
--Economize table: If certain reason is specified, delete unspecified reasons (null ids) or the unmatched reasons
If @SelectR1 Is NOT NULL DELETE FROM #TopNDR WHERE Reason1_Id Is NULL Or Reason1_Id <> @SelectR1  
If @SelectR2 Is NOT NULL DELETE FROM #TopNDR WHERE Reason2_Id Is NULL Or Reason2_Id <> @SelectR2
If @SelectR3 Is NOT NULL DELETE FROM #TopNDR WHERE Reason3_Id Is NULL Or Reason3_Id <> @SelectR3
If @SelectR4 Is NOT NULL DELETE FROM #TopNDR WHERE Reason4_Id Is NULL Or Reason4_Id <> @SelectR4
--We have picked Alarm rows that may have started before the specified @Start_Time or ended after the specified @End_Time 
--Thus we must change change #TopNDR's start and end times to match the specified @Start_Time and @End_Time OR our durations
--will be outside the specified time range
UPDATE #TopNDR SET Start_Time = @Start_Time WHERE Start_Time < @Start_Time
UPDATE #TopNDR SET End_Time = @End_Time WHERE End_Time > @End_Time OR End_Time Is NULL
--Calculate duration based on the specified time range
UPDATE #TopNDR SET duration = DATEDIFF(ss, Start_Time, End_Time) / 60.0
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
--Retreiving Data, replacing Null Reason ID with the wording 'Unspecified'
--
If @ProductSpecified = 1 	 --Return Product-Based Resultset
    BEGIN
 	 If @TimeSort = 1 --Ascending Order
            BEGIN
 	              SELECT   t.Alarm_Id
 	  	  	     , t.Alarm_Desc
 	  	  	     , [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(t.Start_Time,@InTimeZone)
 	  	  	     , [End_Time] = dbo.fnServer_CmnConvertFromDbTime(t.End_Time,@InTimeZone)
 	  	  	     , t.Duration
 	  	  	     , Location = Case When t.Source_Pu_Id Is NULL Then @Unspecified Else pu.Pu_Desc End
 	  	  	     , Reason1 =  Case When t.Reason1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
 	  	  	     , Reason2 =  Case When t.Reason2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End 	  	  	 
 	  	  	     , Reason3 =  Case When t.Reason3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
 	  	  	     , Reason4 =  Case When t.Reason4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
 	  	  	     , t.Prod_Id
 	  	  	     , Prod_Code = Case When t.Prod_Id Is NULL Then NULL Else p.Prod_Code End
 	  	  	     , t.Comment_Id
 	                FROM   #TopNDR t
                       JOIN   Prod_Units pu ON t.Source_Pu_Id = pu.Pu_Id AND pu.Pu_Id <> 0
 	  	        JOIN   Products p ON t.Prod_Id = p.Prod_Id
 	     LEFT OUTER JOIN   Event_Reasons R1 ON t.Reason1_Id = R1.Event_Reason_Id
 	     LEFT OUTER JOIN   Event_Reasons R2 ON t.Reason2_Id = R2.Event_Reason_Id
 	     LEFT OUTER JOIN   Event_Reasons R3 ON t.Reason3_Id = R3.Event_Reason_Id
 	     LEFT OUTER JOIN   Event_Reasons R4 ON t.Reason4_Id = R4.Event_Reason_Id
 	            ORDER BY   t.Start_Time ASC
            END
 	 Else   -- Descending Order
     	     BEGIN
 	              SELECT   t.Alarm_Id
 	  	  	     , t.Alarm_Desc
 	  	  	     , [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(t.Start_Time,@InTimeZone)
 	  	  	     , [End_Time] = dbo.fnServer_CmnConvertFromDbTime(t.End_Time,@InTimeZone)
 	  	  	     , t.Duration
 	  	  	     , Location = Case When t.Source_Pu_Id Is NULL Then @Unspecified Else pu.Pu_Desc End
 	  	  	     , Reason1 =  Case When t.Reason1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
 	  	  	     , Reason2 =  Case When t.Reason2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End 	  	  	 
 	  	  	     , Reason3 =  Case When t.Reason3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
 	  	  	     , Reason4 =  Case When t.Reason4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
 	  	  	     , t.Prod_Id
 	  	  	     , Prod_Code = Case When t.Prod_Id Is NULL Then NULL Else p.Prod_Code End
 	  	  	     , t.Comment_Id
 	                FROM   #TopNDR t
 	  	        JOIN   Products p ON t.Prod_Id = p.Prod_Id
                       JOIN   Prod_Units pu ON t.Source_Pu_Id = pu.Pu_Id AND pu.Pu_Id <> 0
 	     LEFT OUTER JOIN   Event_Reasons R1 ON t.Reason1_Id = R1.Event_Reason_Id
 	     LEFT OUTER JOIN   Event_Reasons R2 ON t.Reason2_Id = R2.Event_Reason_Id
 	     LEFT OUTER JOIN   Event_Reasons R3 ON t.Reason3_Id = R3.Event_Reason_Id
 	     LEFT OUTER JOIN   Event_Reasons R4 ON t.Reason4_Id = R4.Event_Reason_Id
 	            ORDER BY  t.Start_Time DESC
            END
  	 --EndIf ToOrder...
    END
Else --Return Non-Product-Based ResultSet
    BEGIN
        If @TimeSort = 1 --Ascending Order
     	     BEGIN
 	                   SELECT   t.Alarm_Id
 	  	  	          , t.Alarm_Desc
 	  	  	          , [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(t.Start_Time,@InTimeZone)
 	  	  	          , [End_Time] = dbo.fnServer_CmnConvertFromDbTime(t.End_Time,@InTimeZone)
 	  	  	          , t.Duration
 	  	  	          , Location = Case When t.Source_Pu_Id Is NULL Then @Unspecified Else pu.Pu_Desc End
 	  	  	          , Reason1 =  Case When t.Reason1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
 	  	  	          , Reason2 =  Case When t.Reason2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End 	  	  	 
 	  	  	          , Reason3 =  Case When t.Reason3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
 	  	  	          , Reason4 =  Case When t.Reason4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
 	  	  	          , t.Prod_Id
 	  	  	          , Prod_Code = NULL
 	  	  	          , t.Comment_Id 
 	                    FROM   #TopNDR t
                           JOIN   Prod_Units pu ON t.Source_Pu_Id = pu.Pu_Id AND pu.Pu_Id <> 0
 	         LEFT OUTER JOIN   Event_Reasons R1 ON t.Reason1_Id = R1.Event_Reason_Id
 	         LEFT OUTER JOIN   Event_Reasons R2 ON t.Reason2_Id = R2.Event_Reason_Id
 	         LEFT OUTER JOIN   Event_Reasons R3 ON t.Reason3_Id = R3.Event_Reason_Id
 	         LEFT OUTER JOIN   Event_Reasons R4 ON t.Reason4_Id = R4.Event_Reason_Id
 	                ORDER BY   t.Start_Time ASC
            END
        Else   -- Descending Order
            BEGIN
 	                  SELECT   t.Alarm_Id
 	  	  	         , t.Alarm_Desc
 	  	  	         , [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(t.Start_Time,@InTimeZone)
 	  	  	         , [End_Time] = dbo.fnServer_CmnConvertFromDbTime(t.End_Time,@InTimeZone)
 	  	  	         , t.Duration
 	  	  	         , Location = Case When t.Source_Pu_Id Is NULL Then @Unspecified Else pu.Pu_Desc End
 	  	  	         , Reason1 =  Case When t.Reason1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
 	  	  	         , Reason2 =  Case When t.Reason2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End 	  	  	 
 	  	  	         , Reason3 =  Case When t.Reason3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
 	  	  	         , Reason4 =  Case When t.Reason4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
 	  	  	         , t.Prod_Id
 	  	  	         , Prod_Code = NULL
 	  	                 , t.Comment_Id
 	                    FROM   #TopNDR t
                           JOIN   Prod_Units pu ON t.Source_Pu_Id = pu.Pu_Id AND pu.Pu_Id <> 0
 	         LEFT OUTER JOIN   Event_Reasons R1 ON t.Reason1_Id = R1.Event_Reason_Id
 	         LEFT OUTER JOIN   Event_Reasons R2 ON t.Reason2_Id = R2.Event_Reason_Id
 	         LEFT OUTER JOIN   Event_Reasons R3 ON t.Reason3_Id = R3.Event_Reason_Id
 	         LEFT OUTER JOIN   Event_Reasons R4 ON t.Reason4_Id = R4.Event_Reason_Id
 	                ORDER BY  t.Start_Time DESC
            END
        --EndIf ToOrder...
    END --
--EndIf @ProductSpecified = 1
DROP TABLE #TopNDR
DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId

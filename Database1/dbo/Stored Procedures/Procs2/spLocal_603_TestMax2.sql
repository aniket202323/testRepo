
CREATE PROCEDURE [dbo].[spLocal_603_TestMax2]
/*
-------------------------------------------------------------------------------------------------
Stored Procedure	:	spLocal_603_TestMax2
Author				:	Max Brisson 
Date Created		:	28-Jun-2016
SP Type				:  	  	                                
Editor Tab Spacing  :	3

Description         :  
=====================
This stored procedure is for test

CALLED BY			:	Model 603

Revision	Date            Who               	What
========	=============	==================	=====
1.0.0		28-Jun-16		Max Brisson			Creation of SP

TEST CODE:
DECLARE
@Status				int,
@ErrorMsg			varchar(255),
@JumptoTime			datetime,
@ECID					int,
@Reserved1			varchar(30),
@Reserved2			varchar(30),
@Reserved3			varchar(30),
@ChangedTagNum		int,
@ChangedPrevValue	varchar(30),
@ChangedNewValue	varchar(30),
@ChangedPrevTime	datetime,
@ChangedNewTime		datetime,
@Tag1PrevValue		varchar(30),
@Tag1NewValue		varchar(30),
@Tag1PrevTime		datetime,
@Tag1NewTime		datetime

SET @Status	= 1
SET @ErrorMsg = ''
SET @JumptoTime	= '2009-06-17 09:33:58.380'
SET @ECID = 29
SET @Reserved1 = ''
SET @Reserved2 = ''
SET @Reserved3 = ''
SET @ChangedTagNum = 1
SET @ChangedPrevValue = '0'
SET @ChangedNewValue = '1'
SET @ChangedPrevTime = '2009-06-17 09:00:00.000'
SET @ChangedNewTime = '2009-06-17 09:33:58.380'
SET @Tag1PrevValue = '0'
SET @Tag1NewValue = '1'
SET @Tag1PrevTime = '2009-06-17 09:00:00.000'
SET @Tag1NewTime = '2009-06-17 09:33:58.380'


EXEC spLocal_603_TestMax2	@Status, @ErrorMsg, @JumptoTime, @ECID, @Reserved1, @Reserved2, 
								@Reserved3,@ChangedTagNum, @ChangedPrevValue, @ChangedNewValue, 
								@ChangedPrevTime, @ChangedNewTime, @Tag1PrevValue, @Tag1NewValue, 
								@Tag1PrevTime, @Tag1NewTime
SELECT @Status, @ErrorMsg, @JumptoTime
*/ 

-- Parameters list
@Status				int				OUTPUT,
@ErrorMsg			varchar(255)	OUTPUT,
@JumptoTime			datetime		OUTPUT,
@ECID					int,
@Reserved1			varchar(30),
@Reserved2			varchar(30),
@Reserved3			varchar(30),
@ChangedTagNum		int,
@ChangedPrevValue	varchar(30),
@ChangedNewValue	varchar(30),
@ChangedPrevTime	datetime,
@ChangedNewTime	datetime,
@Tag1PrevValue		varchar(30),
@Tag1NewValue		varchar(30),
@Tag1PrevTime		datetime,
@Tag1NewTime		datetime

AS
SET NOCOUNT ON

--------------------------------------
-- Declarations                     --
--------------------------------------
INSERT INTO dbo.Local_Debug
( 
	callingsp, message, Timestamp
)
values
(
		'spLocal_603_TestMax2', '@ChangedTagNum: ' + convert(varchar(25), @ChangedTagNum) + ', @ChangedNewValue: ' +  convert(varchar(25) ,@ChangedNewValue), getdate()
)


SET @Status = 1
SET @ErrorMsg = ''

SET NOCOUNT OFF

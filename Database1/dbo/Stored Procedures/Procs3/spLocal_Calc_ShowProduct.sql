  
--------------------------------------------------------------------------------------------------  
-- Stored Procedure: [spLocal_Calc_ShowProduct]  
--------------------------------------------------------------------------------------------------  
-- Author    : Fernando Rio (Arido Software)  
-- Date created   : 2011-03-17  
-- Version     : Version 1.0.0  
-- SP Type    : Calculation  
-- Caller    : Calculation  
-- Description   : Get the Product Intiated in a PO  
-- Editor tab spacing : 4  
--------------------------------------------------------------------------------------------------  
--------------------------------------------------------------------------------------------------  
-- EDIT HISTORY:  
--------------------------------------------------------------------------------------------------  
-- ========  ====		====					=====  
-- 1.3		2017-08-11	Ryan Burns (Factora)	Reverted @vchPO change since it is pulled before the PO is started
-- 1.2		2017-05-31	Wendy Suen				Updated PO for SCO Compatablility 
-- 1.1		2013-03-01	Namrata Kumar			FO-01660 Add Pu_id validation in SP splocal_Calc_ShowProduct to show correct product code in start up display
-- 1.0		2011-03-17  Fernando Rio			Initial Development  
-- To show up the correct Product on the StartUp display when the Process Order is still in Initiated Status.  
--================================================================================================  
CREATE PROCEDURE [dbo].[spLocal_Calc_ShowProduct]  
--DECLARE  
 @Outputvalue  VARCHAR(25) OUTPUT,  
 @dtmTimeStamp  DATETIME ,  
 @intThisVarID  INT  
AS  
--------------------------------------------------------------------------------------------------  
-- Test Values  
--------------------------------------------------------------------------------------------------  
-- SELECT   
-- @dtmTimeStamp = '02-May-2011 20:14:01',  
-- @intThisVarID = 175  
--------------------------------------------------------------------------------------------------  
--------------------------------------------------------------------------------------------------  
DECLARE  
 @intPUid   INT   ,  
 @intESTId   INT   ,  
 @vchPO    VARCHAR(25) ,  
 @POProductNumber NVARCHAR(50)  
--------------------------------------------------------------------------------------------------  
SET NOCOUNT ON  
--------------------------------------------------------------------------------------------------  
  
--================================================================================================  
--------------------------------------------------------------------------------------------------  

SELECT @intPUid = pu_id FROM dbo.Variables_Base WITH(NOLOCK) WHERE Var_Id = @intThisVarID   

SELECT @intESTId = Event_SubType_Id  
FROM   dbo.Variables_Base v WITH(NOLOCK)  
WHERE Var_Id = @intThisVarID   
  
SELECT	@vchPO	=	UDE_Desc  
FROM	dbo.User_Defined_Events   
WHERE	End_Time				=	@dtmTimeStamp  
	AND		Event_SubType_Id	=	@intESTId  
	AND		PU_Id				=	@intPUid
  
SELECT @POProductNumber = Prod_Code  
    FROM  dbo.Production_Plan pp   WITH(NOLOCK)   
    JOIN  dbo.Products_Base   p     ON p.Prod_id = pp.Prod_Id     
    WHERE  pp.Process_Order = @vchPO  
  
SET @Outputvalue = @POProductNumber  
  
SET NOCOUNT OFF

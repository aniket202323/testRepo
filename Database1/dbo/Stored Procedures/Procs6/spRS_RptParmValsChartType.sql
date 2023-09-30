-----------------------------------------------------------
-- Type: Stored Procedure
-- Name: spRS_RptParmValsChartType
-----------------------------------------------------------
/*
Stored Procedure:  	  spRS_RptParmValsChartType
Author:  	    	    	    	  Matthew Wells (MSI)
Date Created:  	    	  08/27/01
SP Type:  	    	    	  Report Parameter
Tab Spacing:  	    	  4
Description:
=========
Returns the possible values for the subgroup type parameter.
Change Date  	  Who  	  What
===========  	  ====  	  =====
Jan 10 2010 	  	 M.Kravchenko 	 Added 2 more chart types (P/U)
*/
CREATE PROCEDURE [dbo].[spRS_RptParmValsChartType]
AS 
/***********************************************************/
/******** Copyright 2004 GE Fanuc International Inc.********/
/****************** All Rights Reserved ********************/
/***********************************************************/
DECLARE @List TABLE (  	  Id  	    	  int,
  	    	    	    	    	    	  Value  	  varchar(50))
INSERT @List
VALUES (0, 'XBar/MR')
INSERT @List
VALUES (1, 'XBar/Range')
INSERT @List
VALUES (2, 'XBar/Sigma')
INSERT @List
VALUES (3, 'P Chart')
INSERT @List
VALUES (4, 'U Chart')
SELECT Id, Value
FROM @List
SET ANSI_NULLS OFF

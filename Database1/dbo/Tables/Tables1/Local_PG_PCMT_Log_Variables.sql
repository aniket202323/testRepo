﻿CREATE TABLE [dbo].[Local_PG_PCMT_Log_Variables] (
    [Log_id]                INT           IDENTITY (1, 1) NOT NULL,
    [Timestamp]             DATETIME      NOT NULL,
    [User_id]               INT           NOT NULL,
    [Type]                  VARCHAR (50)  NOT NULL,
    [PU_Id]                 INT           NULL,
    [Var_Id]                INT           NULL,
    [Var_Desc]              VARCHAR (50)  NULL,
    [PUG_desc]              VARCHAR (50)  NULL,
    [DS_Id]                 INT           NULL,
    [Event_Type]            TINYINT       NULL,
    [Eng_Units]             VARCHAR (15)  NULL,
    [Test_Name]             VARCHAR (50)  NULL,
    [User_Defined1]         VARCHAR (255) NULL,
    [User_Defined2]         VARCHAR (255) NULL,
    [User_Defined3]         VARCHAR (255) NULL,
    [Data_Type_Id]          INT           NULL,
    [Var_Precision]         TINYINT       NULL,
    [Repeating]             TINYINT       NULL,
    [Repeat_Backtime]       INT           NULL,
    [Base_Var_Id]           INT           NULL,
    [Sampling_Interval]     SMALLINT      NULL,
    [Sampling_Offset]       SMALLINT      NULL,
    [Sampling_Type]         INT           NULL,
    [Spec_Id]               INT           NULL,
    [SA_Id]                 TINYINT       NULL,
    [Extended_Info]         VARCHAR (255) NULL,
    [Calculation_Id]        INT           NULL,
    [Output_Tag]            VARCHAR (100) NULL,
    [Input_Tag]             VARCHAR (100) NULL,
    [Alarm_Template_Id]     INT           NULL,
    [Alarm_Display_Id]      INT           NULL,
    [Autolog_Display_Id]    INT           NULL,
    [Autolog_Display_Order] INT           NULL,
    [External_Link]         VARCHAR (255) NULL
);

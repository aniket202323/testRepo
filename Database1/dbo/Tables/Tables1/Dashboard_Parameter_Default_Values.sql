CREATE TABLE [dbo].[Dashboard_Parameter_Default_Values] (
    [Dashboard_Parameter_Default_Value_ID] INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Parameter_Column]           INT            NOT NULL,
    [Dashboard_Parameter_Row]              INT            NOT NULL,
    [Dashboard_Parameter_Value]            VARCHAR (4000) NOT NULL,
    [Dashboard_Template_Parameter_ID]      INT            NOT NULL,
    CONSTRAINT [PK_Dashboard_Parameter_Default_Values] PRIMARY KEY CLUSTERED ([Dashboard_Parameter_Default_Value_ID] ASC, [Dashboard_Template_Parameter_ID] ASC, [Dashboard_Parameter_Row] ASC, [Dashboard_Parameter_Column] ASC)
);


CREATE TABLE [ecs].[pa_tabs] (
    [id]                BIGINT        IDENTITY (1, 1) NOT NULL,
    [display_name]      VARCHAR (100) NOT NULL,
    [description]       VARCHAR (250) NULL,
    [config_data]       VARCHAR (MAX) NULL,
    [config_expression] VARCHAR (MAX) NULL,
    [standard]          BIT           NOT NULL,
    [created_by]        VARCHAR (50)  NOT NULL,
    [created_on]        DATETIME      NOT NULL,
    [last_modified_by]  VARCHAR (50)  NULL,
    [last_modified_on]  DATETIME      NULL,
    CONSTRAINT [PK_pa_tab] PRIMARY KEY CLUSTERED ([id] ASC)
);


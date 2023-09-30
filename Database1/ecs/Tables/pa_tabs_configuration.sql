CREATE TABLE [ecs].[pa_tabs_configuration] (
    [id]               BIGINT       IDENTITY (1, 1) NOT NULL,
    [app_id]           INT          NOT NULL,
    [pa_tab_id]        BIGINT       NOT NULL,
    [enabled]          BIT          NOT NULL,
    [sequence_order]   INT          NOT NULL,
    [created_by]       VARCHAR (50) NOT NULL,
    [created_on]       DATETIME     NOT NULL,
    [last_modified_by] VARCHAR (50) NULL,
    [last_modified_on] DATETIME     NULL,
    CONSTRAINT [PK_pa_tabs_configuration] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK_pa_tabs_configuration_pa_tab_id_pa_tab_Id] FOREIGN KEY ([pa_tab_id]) REFERENCES [ecs].[pa_tabs] ([id]),
    CONSTRAINT [UC_pa_tabs_configuration] UNIQUE NONCLUSTERED ([id] ASC, [app_id] ASC, [pa_tab_id] ASC)
);


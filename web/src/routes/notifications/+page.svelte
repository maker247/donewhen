<script>
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import PageHeader from '$components/PageHeader.svelte';
	import {
		notifications,
		unreadNotificationsCount,
		refreshNotifications,
		markNotificationsRead,
		markNotificationItemRead,
		isNotificationUnread,
		activeWorkspace,
		aiName
	} from '$lib/store.js';
	import { rel } from '$lib/format.js';
	import {
		Bell,
		Check,
		CheckCheck,
		FileText,
		MessageSquare,
		ExternalLink,
		CircleCheck,
		Search,
		X,
		ChevronLeft,
		ChevronRight,
		ChevronsLeft,
		ChevronsRight
	} from '@lucide/svelte';

	let filterTab = $state('unread'); // 'unread', 'all', 'comments', 'artifacts'
	let search = $state('');
	let currentPage = $state(1);
	let pageSize = $state(10);

	onMount(() => {
		refreshNotifications().catch(() => {});
	});

	const wsId = $derived($activeWorkspace?.id);
	const unreadCount = $derived($unreadNotificationsCount);

	// Whenever tab, search or page size changes, reset to page 1
	$effect(() => {
		filterTab;
		search;
		pageSize;
		currentPage = 1;
	});

	const filteredList = $derived.by(() => {
		$notifications;
		$unreadNotificationsCount;
		const q = search.trim().toLowerCase();

		return $notifications.filter((item) => {
			const unread = isNotificationUnread(item, wsId);

			if (filterTab === 'unread' && !unread) return false;
			if (filterTab === 'comments' && item.kind !== 'commented') return false;
			if (filterTab === 'artifacts' && item.kind !== 'artifact_written') return false;

			if (q) {
				const matchKey = (item.issueKey || '').toLowerCase().includes(q);
				const matchTitle = (item.issueTitle || '').toLowerCase().includes(q);
				const matchDetail = (item.detail || '').toLowerCase().includes(q);
				const matchActor = (item.actor || '').toLowerCase().includes(q);
				if (!matchKey && !matchTitle && !matchDetail && !matchActor) return false;
			}

			return true;
		});
	});

	const totalPages = $derived(Math.max(1, Math.ceil(filteredList.length / pageSize)));
	const startItem = $derived(filteredList.length === 0 ? 0 : (currentPage - 1) * pageSize + 1);
	const endItem = $derived(Math.min(currentPage * pageSize, filteredList.length));
	const paginatedList = $derived(filteredList.slice((currentPage - 1) * pageSize, currentPage * pageSize));

	function goToPage(p) {
		currentPage = Math.max(1, Math.min(p, totalPages));
	}

	function openNotification(item) {
		markNotificationItemRead(item.id);
		if (item.kind === 'artifact_written') {
			if (item.docId) goto(`/artifacts?doc=${item.docId}`);
			else goto('/artifacts');
		} else if (item.issueKey) {
			goto(`/issue/${item.issueKey}`);
		}
	}

	function fullDate(iso) {
		try {
			return new Date(iso).toLocaleString();
		} catch {
			return iso;
		}
	}
</script>

<div class="pg">
	<PageHeader crumbs={[{ label: 'Notifications' }]}>
		{#if unreadCount > 0}
			<button class="btn ghost sm" onclick={markNotificationsRead} title="Mark all notifications as read">
				<Check size={14} strokeWidth={2.4} />
				<span>Mark all read</span>
			</button>
		{/if}
	</PageHeader>

	<div class="pg-body">
		<div class="noti-page">
			<div class="noti-header">
				<div class="noti-headline">
					<h1 class="page-title">Notifications</h1>
					<span class="noti-sub">
						Activity, comments, and artifact updates in {$activeWorkspace?.name || 'this workspace'}
					</span>
				</div>

				<div class="noti-controls">
					<div class="noti-tabs" role="tablist">
						<button
							class="noti-tab"
							class:on={filterTab === 'unread'}
							onclick={() => (filterTab = 'unread')}
						>
							<span>Unread</span>
							{#if unreadCount > 0}
								<span class="tab-badge">{unreadCount > 99 ? '99+' : unreadCount}</span>
							{/if}
						</button>
						<button
							class="noti-tab"
							class:on={filterTab === 'all'}
							onclick={() => (filterTab = 'all')}
						>
							<span>All</span>
							<span class="tab-count">{$notifications.length}</span>
						</button>
						<button
							class="noti-tab"
							class:on={filterTab === 'comments'}
							onclick={() => (filterTab = 'comments')}
						>
							<span>Comments</span>
						</button>
						<button
							class="noti-tab"
							class:on={filterTab === 'artifacts'}
							onclick={() => (filterTab = 'artifacts')}
						>
							<span>Artifacts</span>
						</button>
					</div>

					<div class="noti-tools">
						<div class="search-box">
							<Search size={14} strokeWidth={2} class="search-ic" />
							<input
								type="text"
								class="search-input"
								placeholder="Filter notifications…"
								bind:value={search}
							/>
							{#if search}
								<button class="search-clear" onclick={() => (search = '')} aria-label="Clear filter">
									<X size={12} strokeWidth={2.4} />
								</button>
							{/if}
						</div>

						{#if totalPages > 1}
							<div class="compact-paging">
								<button
									class="paging-btn sm"
									disabled={currentPage <= 1}
									onclick={() => goToPage(currentPage - 1)}
									title="Previous page"
									aria-label="Previous page"
								>
									<ChevronLeft size={13} strokeWidth={2} />
								</button>
								<span class="compact-page-info">{currentPage}/{totalPages}</span>
								<button
									class="paging-btn sm"
									disabled={currentPage >= totalPages}
									onclick={() => goToPage(currentPage + 1)}
									title="Next page"
									aria-label="Next page"
								>
									<ChevronRight size={13} strokeWidth={2} />
								</button>
							</div>
						{/if}
					</div>
				</div>
			</div>

			<div class="noti-content">
				{#if filteredList.length === 0}
					<div class="empty-state">
						<div class="empty-ic-wrap">
							{#if filterTab === 'unread' && !search}
								<CheckCheck size={28} strokeWidth={2} />
							{:else}
								<Bell size={28} strokeWidth={1.7} />
							{/if}
						</div>
						<div class="empty-title">
							{#if filterTab === 'unread' && !search}
								All caught up!
							{:else if search}
								No matching notifications
							{:else}
								No notifications yet
							{/if}
						</div>
						<div class="empty-desc">
							{#if filterTab === 'unread' && !search}
								There are no unread notifications in {$activeWorkspace?.name || 'this workspace'}.
							{:else if search}
								No notifications matched "{search}". Try searching for something else.
							{:else}
								When someone or an AI agent comments on a task, creates an artifact, or updates an issue, it will show up here.
							{/if}
						</div>
						{#if filterTab === 'unread' && $notifications.length > 0}
							<button class="btn ghost sm" onclick={() => (filterTab = 'all')}>
								View all notifications ({$notifications.length})
							</button>
						{/if}
					</div>
				{:else}
					<div class="cards-list">
						{#each paginatedList as item (item.id)}
							{@const isUn = isNotificationUnread(item, wsId)}
							<div class="noti-card" class:unread={isUn}>
								<div class="card-rail">
									{#if isUn}
										<span class="card-dot" title="Unread notification"></span>
									{:else}
										<span class="card-dot-read"></span>
									{/if}
								</div>

								<div class="card-main">
									<div class="card-meta">
										<div class="card-tags">
											{#if item.kind === 'artifact_written'}
												<span class="tag artifact">
													<FileText size={12} strokeWidth={2.2} />
													<span>Artifact</span>
												</span>
											{:else if item.kind === 'commented'}
												<span class="tag comment">
													<MessageSquare size={12} strokeWidth={2.2} />
													<span>Comment</span>
												</span>
											{:else if item.kind === 'state_changed'}
												<span class="tag state">
													<CircleCheck size={12} strokeWidth={2.2} />
													<span>Status</span>
												</span>
											{:else}
												<span class="tag task">
													<CircleCheck size={12} strokeWidth={2.2} />
													<span>Task</span>
												</span>
											{/if}

											{#if item.issueKey}
												<button
													class="key-link"
													onclick={() => openNotification(item)}
													title="Open issue {item.issueKey}"
												>
													<span class="mono">{item.issueKey}</span>
												</button>
											{/if}
										</div>

										<div class="card-meta-right">
											<span class="time-stamp" title={fullDate(item.createdAt)}>
												{rel(item.createdAt)}
											</span>
										</div>
									</div>

									<div class="card-headline">
										<button class="headline-link" onclick={() => openNotification(item)}>
											{#if item.kind === 'artifact_written'}
												{item.detail || 'Untitled artifact'}
											{:else}
												{item.issueTitle || item.issueKey || 'Untitled task'}
											{/if}
										</button>
									</div>

									<div class="card-actor-row">
										<span class="actor-badge" class:ai={item.actor === 'ai'}>
											{item.actor === 'ai' ? `✦ ${$aiName}` : 'Member'}
										</span>
										{#if item.kind === 'artifact_written'}
											{#if item.issueKey}
												<span class="actor-action">attached artifact to {item.issueKey}</span>
											{:else}
												<span class="actor-action">published a new workspace artifact</span>
											{/if}
										{:else if item.kind === 'created'}
											<span class="actor-action">created this task</span>
										{:else if item.kind === 'state_changed'}
											<span class="actor-action">moved to {item.toVal || item.detail || 'new status'}</span>
										{:else}
											<span class="actor-action">commented:</span>
										{/if}
									</div>

									{#if item.kind === 'commented' && item.detail}
										<div class="comment-body">
											{item.detail}
										</div>
									{/if}

									<div class="card-actions">
										<button class="btn secondary sm" onclick={() => openNotification(item)}>
											<span>{item.kind === 'artifact_written' ? 'Open artifact' : 'Open task'}</span>
											<ExternalLink size={12} strokeWidth={2.2} />
										</button>
										{#if isUn}
											<button
												class="btn ghost sm"
												onclick={() => markNotificationItemRead(item.id)}
												title="Mark as read"
											>
												<Check size={13} strokeWidth={2.4} />
												<span>Mark read</span>
											</button>
										{/if}
									</div>
								</div>
							</div>
						{/each}
					</div>

					<!-- Pagination footer -->
					<div class="paging-bar">
						<div class="paging-summary">
							<span>Showing {startItem}–{endItem} of {filteredList.length}</span>
						</div>

						<div class="paging-controls">
							<div class="page-size-wrap">
								<span class="page-size-label">Per page:</span>
								<select
									class="page-size-select"
									bind:value={pageSize}
									aria-label="Items per page"
								>
									<option value={10}>10</option>
									<option value={15}>15</option>
									<option value={25}>25</option>
									<option value={50}>50</option>
								</select>
							</div>

							{#if totalPages > 1}
								<div class="paging-btns">
									<button
										class="paging-btn"
										disabled={currentPage <= 1}
										onclick={() => goToPage(1)}
										title="First page"
										aria-label="First page"
									>
										<ChevronsLeft size={14} strokeWidth={2} />
									</button>
									<button
										class="paging-btn"
										disabled={currentPage <= 1}
										onclick={() => goToPage(currentPage - 1)}
										title="Previous page"
										aria-label="Previous page"
									>
										<ChevronLeft size={14} strokeWidth={2} />
									</button>

									<span class="page-info">
										Page <b>{currentPage}</b> of <b>{totalPages}</b>
									</span>

									<button
										class="paging-btn"
										disabled={currentPage >= totalPages}
										onclick={() => goToPage(currentPage + 1)}
										title="Next page"
										aria-label="Next page"
									>
										<ChevronRight size={14} strokeWidth={2} />
									</button>
									<button
										class="paging-btn"
										disabled={currentPage >= totalPages}
										onclick={() => goToPage(totalPages)}
										title="Last page"
										aria-label="Last page"
									>
										<ChevronsRight size={14} strokeWidth={2} />
									</button>
								</div>
							{/if}
						</div>
					</div>
				{/if}
			</div>
		</div>
	</div>
</div>

<style>
	.noti-page {
		max-width: 920px;
		margin: 0 auto;
		padding: 24px 20px 60px;
		display: flex;
		flex-direction: column;
		gap: 20px;
	}
	.noti-header {
		display: flex;
		flex-direction: column;
		gap: 16px;
	}
	.noti-headline {
		display: flex;
		flex-direction: column;
		gap: 4px;
	}
	.noti-sub {
		font-size: var(--t-sm);
		color: var(--ink-2);
	}
	.noti-controls {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 12px;
		flex-wrap: wrap;
	}
	.noti-tabs {
		display: flex;
		align-items: center;
		gap: 4px;
		background: var(--sunken);
		padding: 3px;
		border-radius: var(--r);
		border: 1px solid var(--line);
	}
	.noti-tab {
		display: inline-flex;
		align-items: center;
		gap: 6px;
		background: none;
		border: none;
		font-family: inherit;
		font-size: var(--t-xs);
		font-weight: 500;
		color: var(--ink-2);
		padding: 5px 10px;
		border-radius: var(--r-sm);
		cursor: pointer;
		transition: background 0.1s, color 0.1s;
	}
	.noti-tab:hover {
		color: var(--ink);
	}
	.noti-tab.on {
		background: var(--surface);
		color: var(--ink);
		font-weight: 600;
		box-shadow: var(--shadow-1);
	}
	.tab-badge {
		background: var(--accent);
		color: var(--paper);
		font-family: var(--mono);
		font-size: var(--t-xs);
		font-weight: 600;
		padding: 0 5px;
		border-radius: 9999px;
		min-width: 16px;
		height: 16px;
		line-height: 16px;
		text-align: center;
	}
	.tab-count {
		font-family: var(--mono);
		font-size: var(--t-xs);
		color: var(--ink-3);
	}
	.noti-tools {
		display: flex;
		align-items: center;
		gap: 10px;
	}
	.compact-paging {
		display: flex;
		align-items: center;
		gap: 4px;
		background: var(--sunken);
		padding: 2px 4px;
		border-radius: var(--r-sm);
		border: 1px solid var(--line);
	}
	.compact-page-info {
		font-family: var(--mono);
		font-size: var(--t-xs);
		color: var(--ink-2);
		padding: 0 4px;
	}
	.search-box {
		position: relative;
		display: flex;
		align-items: center;
		min-width: 200px;
	}
	:global(.search-ic) {
		position: absolute;
		left: 10px;
		color: var(--ink-3);
		pointer-events: none;
	}
	.search-input {
		width: 100%;
		height: 32px;
		padding: 0 28px 0 30px;
		border: 1px solid var(--line);
		border-radius: var(--r-sm);
		background: var(--surface);
		font-family: inherit;
		font-size: var(--t-sm);
		color: var(--ink);
		outline: none;
		transition: border-color 0.12s;
	}
	.search-input:focus {
		border-color: var(--accent);
	}
	.search-clear {
		position: absolute;
		right: 6px;
		background: none;
		border: none;
		color: var(--ink-3);
		padding: 4px;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		border-radius: var(--r-sm);
	}
	.search-clear:hover {
		color: var(--ink);
	}
	.noti-content {
		display: flex;
		flex-direction: column;
		gap: 12px;
	}
	.empty-state {
		display: flex;
		flex-direction: column;
		align-items: center;
		text-align: center;
		padding: 60px 20px;
		background: var(--surface);
		border: 1px dashed var(--line-strong);
		border-radius: var(--r-lg);
		gap: 8px;
	}
	.empty-ic-wrap {
		width: 52px;
		height: 52px;
		border-radius: 50%;
		background: var(--sunken);
		color: var(--accent);
		display: flex;
		align-items: center;
		justify-content: center;
		margin-bottom: 6px;
	}
	.empty-title {
		font-size: var(--t-base);
		font-weight: 600;
		color: var(--ink);
	}
	.empty-desc {
		font-size: var(--t-sm);
		color: var(--ink-2);
		max-width: 380px;
		line-height: 1.5;
		margin-bottom: 8px;
	}
	.cards-list {
		display: flex;
		flex-direction: column;
		gap: 10px;
	}
	.noti-card {
		display: flex;
		gap: 14px;
		padding: 16px 18px;
		background: var(--surface);
		border: 1px solid var(--line);
		border-radius: var(--r-lg);
		transition: border-color 0.15s, box-shadow 0.15s;
	}
	.noti-card:hover {
		border-color: var(--line-strong);
		box-shadow: var(--shadow-1);
	}
	.noti-card.unread {
		background: var(--paper);
		border-color: var(--accent);
		box-shadow: 0 1px 3px oklch(0 0 0 / 0.05);
	}
	.card-rail {
		display: flex;
		align-items: flex-start;
		padding-top: 4px;
		flex: none;
	}
	.card-dot {
		width: 8px;
		height: 8px;
		border-radius: 50%;
		background: var(--accent);
	}
	.card-dot-read {
		width: 8px;
		height: 8px;
		border-radius: 50%;
		background: var(--line);
	}
	.card-main {
		flex: 1;
		min-width: 0;
		display: flex;
		flex-direction: column;
		gap: 8px;
	}
	.card-meta {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 10px;
	}
	.card-tags {
		display: flex;
		align-items: center;
		gap: 8px;
		flex-wrap: wrap;
	}
	.tag {
		display: inline-flex;
		align-items: center;
		gap: 4px;
		font-family: var(--mono);
		font-size: var(--t-xs);
		font-weight: 600;
		padding: 2px 7px;
		border-radius: var(--r-sm);
	}
	.tag.artifact {
		background: var(--sunken);
		color: var(--accent);
	}
	.tag.comment {
		background: var(--sunken);
		color: var(--ink-2);
	}
	.tag.state {
		background: var(--sunken);
		color: var(--ink-2);
	}
	.tag.task {
		background: var(--sunken);
		color: var(--ink-2);
	}
	.key-link {
		background: none;
		border: none;
		cursor: pointer;
		padding: 0;
		color: var(--ink);
		font-family: inherit;
	}
	.key-link:hover .mono {
		text-decoration: underline;
		color: var(--accent);
	}
	.mono {
		font-family: var(--mono);
		font-size: var(--t-xs);
		font-weight: 600;
	}
	.card-meta-right {
		display: flex;
		align-items: center;
		gap: 8px;
	}
	.time-stamp {
		font-size: var(--t-xs);
		color: var(--ink-3);
		white-space: nowrap;
	}
	.card-headline {
		font-size: var(--t-base);
		font-weight: 600;
		color: var(--ink);
		line-height: 1.35;
	}
	.headline-link {
		background: none;
		border: none;
		padding: 0;
		font: inherit;
		color: inherit;
		cursor: pointer;
		text-align: left;
	}
	.headline-link:hover {
		color: var(--accent);
	}
	.card-actor-row {
		display: flex;
		align-items: center;
		gap: 6px;
		font-size: var(--t-sm);
		color: var(--ink-2);
	}
	.actor-badge {
		font-weight: 600;
		color: var(--ink);
	}
	.actor-badge.ai {
		color: var(--accent);
	}
	.actor-action {
		color: var(--ink-3);
	}
	.comment-body {
		background: var(--sunken);
		border: 1px solid var(--line);
		border-radius: var(--r);
		padding: 10px 14px;
		font-size: var(--t-sm);
		color: var(--ink);
		line-height: 1.5;
		white-space: pre-wrap;
		word-break: break-word;
	}
	.card-actions {
		display: flex;
		align-items: center;
		gap: 8px;
		margin-top: 4px;
	}
	.paging-bar {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 16px;
		padding: 14px 18px;
		background: var(--surface);
		border: 1px solid var(--line);
		border-radius: var(--r-lg);
		flex-wrap: wrap;
	}
	.paging-summary {
		font-size: var(--t-xs);
		color: var(--ink-2);
		font-family: var(--mono);
	}
	.paging-controls {
		display: flex;
		align-items: center;
		gap: 16px;
	}
	.page-size-wrap {
		display: flex;
		align-items: center;
		gap: 6px;
		font-size: var(--t-xs);
		color: var(--ink-3);
	}
	.page-size-select {
		height: 28px;
		padding: 0 8px;
		border: 1px solid var(--line);
		border-radius: var(--r-sm);
		background: var(--paper);
		color: var(--ink);
		font-size: var(--t-xs);
		font-family: var(--mono);
		outline: none;
		cursor: pointer;
	}
	.paging-btns {
		display: flex;
		align-items: center;
		gap: 4px;
	}
	.paging-btn {
		width: 28px;
		height: 28px;
		border: 1px solid var(--line);
		border-radius: var(--r-sm);
		background: var(--paper);
		color: var(--ink-2);
		display: inline-flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		transition: background 0.1s, color 0.1s, border-color 0.1s;
	}
	.paging-btn.sm {
		width: 24px;
		height: 24px;
	}
	.paging-btn:hover:not(:disabled) {
		background: var(--hover);
		color: var(--ink);
		border-color: var(--line-strong);
	}
	.paging-btn:disabled {
		opacity: 0.4;
		cursor: not-allowed;
	}
	.page-info {
		font-size: var(--t-xs);
		color: var(--ink-2);
		padding: 0 8px;
		white-space: nowrap;
	}
	.page-info b {
		color: var(--ink);
		font-family: var(--mono);
	}
</style>

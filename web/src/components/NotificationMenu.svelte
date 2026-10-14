<script>
	import { goto } from '$app/navigation';
	import { Check, CheckCheck, FileText, ArrowRight } from '@lucide/svelte';
	import {
		notifications,
		unreadNotificationsCount,
		markNotificationsRead,
		markNotificationItemRead,
		isNotificationUnread,
		activeWorkspace,
		aiName
	} from '$lib/store.js';
	import { rel } from '$lib/format.js';

	let { onclose = () => {} } = $props();

	// Explicitly depend on unreadNotificationsCount so when markNotificationsRead runs, unreadList re-filters immediately
	const unreadList = $derived.by(() => {
		$unreadNotificationsCount;
		const wsId = $activeWorkspace?.id;
		return $notifications.filter((item) => isNotificationUnread(item, wsId));
	});

	function handleMarkRead(e) {
		e.stopPropagation();
		markNotificationsRead();
	}

	function openItem(item) {
		markNotificationItemRead(item.id);
		onclose();
		if (item.kind === 'artifact_written') {
			if (item.docId) goto(`/artifacts?doc=${item.docId}`);
			else goto('/artifacts');
		} else if (item.issueKey) {
			goto(`/issue/${item.issueKey}`);
		}
	}

	function viewAll() {
		onclose();
		goto('/notifications');
	}
</script>

<div class="nb-dropdown" role="menu">
	<div class="nb-header">
		<div class="nb-title">
			<span>Notifications</span>
			{#if unreadList.length > 0}
				<span class="nb-pill">{unreadList.length} unread</span>
			{/if}
		</div>
		{#if unreadList.length > 0}
			<button class="nb-read-btn" onclick={handleMarkRead} title="Mark all as read">
				<Check size={13} strokeWidth={2.4} />
				<span>Mark read</span>
			</button>
		{/if}
	</div>

	<div class="nb-list">
		{#if unreadList.length === 0}
			<div class="nb-empty">
				<div class="nb-empty-check">
					<CheckCheck size={22} strokeWidth={2} />
				</div>
				<div class="nb-empty-title">All caught up</div>
				<div class="nb-empty-sub">No unread notifications in {$activeWorkspace?.name || 'this workspace'}.</div>
			</div>
		{:else}
			{#each unreadList as item (item.id)}
				<button class="nb-item" onclick={() => openItem(item)}>
					<div class="nb-item-top">
						<div class="nb-item-key">
							<span class="nb-dot"></span>
							{#if item.kind === 'artifact_written'}
								<span class="nb-tag-artifact">
									<FileText size={11} strokeWidth={2.2} />
									<span>Artifact</span>
								</span>
							{:else}
								<span class="mono">{item.issueKey || 'Task'}</span>
							{/if}
						</div>
						<span class="nb-item-time">{rel(item.createdAt)}</span>
					</div>

					{#if item.kind === 'artifact_written'}
						<div class="nb-item-task">{item.detail || 'Untitled artifact'}</div>
						<div class="nb-item-msg">
							<span class="nb-item-actor" class:ai={item.actor === 'ai'}>
								{item.actor === 'ai' ? `✦ ${$aiName}` : 'Member'}
							</span>
							{#if item.issueKey}
								<span>attached to {item.issueKey}</span>
							{:else}
								<span>created a new artifact</span>
							{/if}
						</div>
					{:else if item.kind === 'created'}
						<div class="nb-item-task">{item.issueTitle || 'Untitled task'}</div>
						<div class="nb-item-msg">
							<span class="nb-item-actor" class:ai={item.actor === 'ai'}>
								{item.actor === 'ai' ? `✦ ${$aiName}` : 'Member'}
							</span>
							<span>created this task</span>
						</div>
					{:else if item.kind === 'state_changed'}
						<div class="nb-item-task">{item.issueTitle || 'Untitled task'}</div>
						<div class="nb-item-msg">
							<span class="nb-item-actor" class:ai={item.actor === 'ai'}>
								{item.actor === 'ai' ? `✦ ${$aiName}` : 'Member'}
							</span>
							<span>moved to {item.toVal || item.detail || 'new status'}</span>
						</div>
					{:else}
						<div class="nb-item-task">{item.issueTitle || 'Untitled task'}</div>
						<div class="nb-item-msg">
							<span class="nb-item-actor" class:ai={item.actor === 'ai'}>
								{item.actor === 'ai' ? `✦ ${$aiName}` : 'Member'}:
							</span>
							<span class="nb-item-body">{item.detail}</span>
						</div>
					{/if}
				</button>
			{/each}
		{/if}
	</div>

	<div class="nb-footer">
		<button class="nb-viewall-btn" onclick={viewAll}>
			<span>View all in detail view</span>
			<ArrowRight size={13} strokeWidth={2} />
		</button>
	</div>
</div>

<style>
	.nb-dropdown {
		width: 340px;
		max-width: min(340px, 92vw);
		background: var(--surface);
		border: 1px solid var(--line);
		border-radius: var(--r-lg);
		box-shadow: var(--shadow-2);
		display: flex;
		flex-direction: column;
		overflow: hidden;
	}
	.nb-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 10px 14px;
		border-bottom: 1px solid var(--line);
		background: var(--paper);
	}
	.nb-title {
		display: flex;
		align-items: center;
		gap: 8px;
		font-size: var(--t-sm);
		font-weight: 600;
		color: var(--ink);
	}
	.nb-pill {
		font-family: var(--mono);
		font-size: var(--t-xs);
		background: var(--accent);
		color: var(--paper);
		padding: 1px 6px;
		border-radius: 9999px;
		font-weight: 500;
	}
	.nb-read-btn {
		background: none;
		border: none;
		color: var(--ink-3);
		font-size: var(--t-xs);
		display: inline-flex;
		align-items: center;
		gap: 4px;
		cursor: pointer;
		padding: 2px 6px;
		border-radius: var(--r-sm);
		font-family: inherit;
	}
	.nb-read-btn:hover {
		background: var(--hover);
		color: var(--ink);
	}
	.nb-list {
		max-height: 380px;
		overflow-y: auto;
		display: flex;
		flex-direction: column;
	}
	.nb-item {
		display: flex;
		flex-direction: column;
		gap: 4px;
		padding: 10px 14px;
		text-align: left;
		background: none;
		border: none;
		border-bottom: 1px solid var(--line);
		cursor: pointer;
		transition: background 0.1s;
		width: 100%;
		box-sizing: border-box;
		font-family: inherit;
	}
	.nb-item:last-child {
		border-bottom: none;
	}
	.nb-item:hover {
		background: var(--hover);
	}
	.nb-item-top {
		display: flex;
		align-items: center;
		justify-content: space-between;
	}
	.nb-item-key {
		display: flex;
		align-items: center;
		gap: 6px;
	}
	.nb-dot {
		width: 6px;
		height: 6px;
		border-radius: 50%;
		background: var(--accent);
		flex: none;
	}
	.nb-item-key .mono {
		font-family: var(--mono);
		font-size: var(--t-xs);
		font-weight: 600;
		color: var(--ink);
	}
	.nb-tag-artifact {
		display: inline-flex;
		align-items: center;
		gap: 4px;
		font-family: var(--mono);
		font-size: var(--t-xs);
		font-weight: 600;
		color: var(--accent);
		background: var(--sunken);
		padding: 1px 5px;
		border-radius: var(--r-sm);
	}
	.nb-item-time {
		font-size: var(--t-xs);
		color: var(--ink-3);
	}
	.nb-item-task {
		font-size: var(--t-sm);
		font-weight: 500;
		color: var(--ink);
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.nb-item-msg {
		font-size: var(--t-xs);
		color: var(--ink-2);
		line-height: 1.4;
		overflow: hidden;
		text-overflow: ellipsis;
		display: -webkit-box;
		-webkit-line-clamp: 2;
		-webkit-box-orient: vertical;
	}
	.nb-item-actor {
		font-weight: 500;
		color: var(--ink);
	}
	.nb-item-actor.ai {
		color: var(--accent);
	}
	.nb-empty {
		padding: 36px 18px;
		text-align: center;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 6px;
		color: var(--ink-3);
	}
	.nb-empty-check {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 40px;
		height: 40px;
		border-radius: 50%;
		background: var(--sunken);
		color: var(--accent);
		margin-bottom: 4px;
	}
	.nb-empty-title {
		font-size: var(--t-sm);
		font-weight: 600;
		color: var(--ink);
	}
	.nb-empty-sub {
		font-size: var(--t-xs);
		color: var(--ink-3);
		max-width: 240px;
		line-height: 1.4;
	}
	.nb-footer {
		border-top: 1px solid var(--line);
		background: var(--paper);
		padding: 6px 10px;
	}
	.nb-viewall-btn {
		width: 100%;
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 6px;
		background: none;
		border: none;
		padding: 7px;
		border-radius: var(--r-sm);
		font-size: var(--t-xs);
		font-weight: 500;
		color: var(--accent);
		cursor: pointer;
		font-family: inherit;
		transition: background 0.1s;
	}
	.nb-viewall-btn:hover {
		background: var(--hover);
	}
</style>

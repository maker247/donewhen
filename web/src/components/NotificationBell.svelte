<script>
	import { onMount } from 'svelte';
	import { Bell } from '@lucide/svelte';
	import { unreadNotificationsCount, refreshNotifications } from '$lib/store.js';
	import NotificationMenu from './NotificationMenu.svelte';

	let open = $state(false);

	onMount(() => {
		refreshNotifications().catch(() => {});
	});

	function toggle() {
		open = !open;
	}
</script>

<div class="nb-wrap">
	<button
		class="nb-btn"
		class:has-unread={$unreadNotificationsCount > 0}
		class:open={open}
		onclick={toggle}
		aria-label="Notifications"
		title="Notifications"
		aria-haspopup="true"
		aria-expanded={open}
	>
		<Bell size={16} strokeWidth={2} />
		{#if $unreadNotificationsCount > 0}
			<span class="nb-badge">
				{$unreadNotificationsCount > 9 ? '9+' : $unreadNotificationsCount}
			</span>
		{/if}
	</button>

	{#if open}
		<div class="dd-bd" role="presentation" onclick={() => (open = false)}></div>
		<div class="nb-dropdown-wrap">
			<NotificationMenu onclose={() => (open = false)} />
		</div>
	{/if}
</div>

<style>
	.nb-wrap {
		position: relative;
		display: inline-flex;
		align-items: center;
		flex-shrink: 0;
	}
	.nb-btn {
		position: relative;
		width: 32px;
		height: 32px;
		background: none;
		border: 1px solid transparent;
		color: var(--ink-2);
		border-radius: var(--r-sm);
		display: inline-flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		transition: background 0.12s, color 0.12s, border-color 0.12s;
	}
	.nb-btn:hover {
		background: var(--hover);
		color: var(--ink);
	}
	.nb-btn.has-unread {
		color: var(--ink);
	}
	.nb-btn.open {
		background: var(--hover);
		color: var(--ink);
		border-color: var(--line);
	}
	.nb-badge {
		position: absolute;
		top: -2px;
		right: -4px;
		background: var(--accent);
		color: var(--paper);
		font-family: var(--mono);
		font-size: var(--t-xs);
		font-weight: 600;
		min-width: 16px;
		height: 16px;
		line-height: 16px;
		padding: 0 4px;
		border-radius: 9999px;
		text-align: center;
		display: flex;
		align-items: center;
		justify-content: center;
		box-shadow: 0 0 0 1.5px var(--paper);
	}
	.dd-bd {
		position: fixed;
		inset: 0;
		z-index: 100;
	}
	.nb-dropdown-wrap {
		position: absolute;
		top: calc(100% + 6px);
		right: 0;
		z-index: 101;
	}
</style>

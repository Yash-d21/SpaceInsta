document.addEventListener('DOMContentLoaded', () => {
    // Auth elements
    const loginOverlay = document.getElementById('loginOverlay');
    const loginForm = document.getElementById('loginForm');
    const mainDashboard = document.getElementById('mainDashboard');
    const displayUsername = document.getElementById('displayUsername');

    // UI Navigation elements
    const historySection = document.getElementById('historySection');
    const configSection = document.getElementById('configSection');
    const historyGrid = document.getElementById('historyGrid');

    // Analysis elements
    const fileInput = document.getElementById('fileInput');
    const dropZone = document.getElementById('dropZone');
    const step1 = document.getElementById('step1');
    const step2 = document.getElementById('step2');
    const generateSpecsBtn = document.getElementById('generateSpecsBtn');
    const generateMoreBtn = document.getElementById('generateMoreBtn');
    const specSelectionSection = document.getElementById('specSelectionSection');
    const specsGrid = document.getElementById('specsGrid');
    const resultsContainer = document.getElementById('results');
    const loader = document.getElementById('loader');
    const imagePreview = document.getElementById('imagePreview');
    const imagePreviewContainer = document.getElementById('imagePreviewContainer');

    const finalDesignImage = document.getElementById('finalDesignImage');
    const finalDesignTitle = document.getElementById('finalDesignTitle');
    const finalDesignVibe = document.getElementById('finalDesignVibe');

    let currentFile = null;
    let tempFilePath = null;
    let user = null;

    // Budget Slider Logic
    const budgetInput = document.getElementById('budgetInput');
    const budgetDisplay = document.getElementById('budgetDisplay');
    const budgetHidden = document.getElementById('budgetSelect');

    budgetInput.addEventListener('input', (e) => {
        const val = e.target.value;
        budgetDisplay.innerText = `₹${val}L`;
        budgetHidden.value = `${val}L`;
    });

    // --- Fake Auth Logic ---
    function checkAuth() {
        const savedUser = localStorage.getItem('is_user');
        if (savedUser) {
            login(savedUser);
        }
    }

    function login(username) {
        user = username;
        localStorage.setItem('is_user', username);
        displayUsername.innerText = username;
        // loginOverlay.style.display = 'none'; // Keep overlay hidden/visible handled by CSS if needed, but here we just hide it.
        loginOverlay.style.display = 'none';
        mainDashboard.style.display = 'block';

        // Render Dock
        renderDock();
        document.getElementById('dockContainer').style.display = 'block';
        document.getElementById('userBadgeHeader').style.display = 'flex'; // Show user badge in top right

        loadHistory();
    }

    loginForm.addEventListener('submit', (e) => {
        e.preventDefault();
        const username = document.getElementById('username').value;
        if (username) login(username);
    });

    // --- Navigation Logic (Dock Actions) ---
    function renderDock() {
        const dockContainer = document.getElementById('dockContainer');
        dockContainer.innerHTML = `
            <div class="dock-outer">
                <div class="dock-panel">
                    <div class="dock-item" onclick="handleDockAction('home')">
                        <div class="dock-icon"><i class="fa-solid fa-house"></i></div>
                        <div class="dock-label">Home</div>
                    </div>
                    <div class="dock-item" onclick="handleDockAction('history')">
                        <div class="dock-icon"><i class="fa-solid fa-clock-rotate-left"></i></div>
                        <div class="dock-label">History</div>
                    </div>
                    <div class="dock-item" onclick="handleDockAction('new')">
                        <div class="dock-icon"><i class="fa-solid fa-plus"></i></div>
                        <div class="dock-label">New</div>
                    </div>
                    <div class="dock-item" onclick="handleDockAction('logout')">
                        <div class="dock-icon"><i class="fa-solid fa-right-from-bracket" style="color: var(--error);"></i></div>
                        <div class="dock-label">Logout</div>
                    </div>
                </div>
            </div>
        `;
    }

    window.handleDockAction = (action) => {
        if (action === 'home' || action === 'new') {
            historySection.style.display = 'none';
            specSelectionSection.style.display = 'none';
            resultsContainer.style.display = 'none';
            imagePreviewContainer.style.display = 'none';
            configSection.style.display = 'block';
            step1.style.display = 'block';
            step2.style.display = 'none';
            fileInput.value = '';
            currentFile = null;
        } else if (action === 'history') {
            configSection.style.display = 'none';
            specSelectionSection.style.display = 'none';
            resultsContainer.style.display = 'none';
            imagePreviewContainer.style.display = 'none';
            historySection.style.display = 'block';
            loadHistory();
        } else if (action === 'logout') {
            localStorage.removeItem('is_user');
            window.location.reload();
        }
    };

    /* 
    // Legacy Nav Listeners - Removed in favor of Dock
    historyBtn.addEventListener('click', () => { ... });
    newAnalysisBtn.addEventListener('click', () => { ... });
    */

    // --- History Logic ---
    function saveToHistory(data) {
        let history = JSON.parse(localStorage.getItem(`history_${user}`) || '[]');
        history.unshift({
            date: new Date().toLocaleDateString(),
            time: new Date().toLocaleTimeString(),
            ...data
        });
        localStorage.setItem(`history_${user}`, JSON.stringify(history));
    }

    function loadHistory() {
        const history = JSON.parse(localStorage.getItem(`history_${user}`) || '[]');
        historyGrid.innerHTML = '';

        if (history.length === 0) {
            historyGrid.innerHTML = '<p style="text-align: center; grid-column: 1/-1; color: var(--text-muted); padding: 40px;">No design history yet. Start a new analysis!</p>';
            return;
        }

        history.forEach((item) => {
            const card = document.createElement('div');
            card.className = 'glass-card history-card';
            card.innerHTML = `
                <img src="${item.spec.image_url}" class="history-item-img">
                <div class="tag">${item.vision.room_type}</div>
                <h3 style="margin-top: 15px;">${item.spec.title}</h3>
                <p style="font-size: 0.8rem; color: var(--text-muted); margin-top: 5px;">${item.date} • ${item.time}</p>
                <div class="data-row" style="margin-top: 20px; border-top: 1px solid #f5f5f7; border-bottom: none;">
                    <span class="data-label">Estimate</span>
                    <span class="data-value" style="color: var(--primary);">₹${item.costs.premium.total.toLocaleString()}</span>
                </div>
            `;
            card.addEventListener('click', () => {
                displayFinalResults(item.full_data);
                historySection.style.display = 'none';
                resultsContainer.style.display = 'block';
            });
            historyGrid.appendChild(card);
        });
    }

    // --- Drag & Drop ---
    dropZone.addEventListener('click', () => fileInput.click());

    dropZone.addEventListener('dragover', (e) => {
        e.preventDefault();
        dropZone.classList.add('active');
    });

    dropZone.addEventListener('dragleave', () => {
        dropZone.classList.remove('active');
    });

    dropZone.addEventListener('drop', (e) => {
        e.preventDefault();
        dropZone.classList.remove('active');
        const file = e.dataTransfer.files[0];
        if (file && file.type.startsWith('image/')) {
            handleFile(file);
        }
    });

    fileInput.addEventListener('change', (e) => {
        if (e.target.files[0]) handleFile(e.target.files[0]);
    });

    function handleFile(file) {
        currentFile = file;
        const reader = new FileReader();
        reader.onload = (event) => {
            imagePreview.src = event.target.result;
            imagePreviewContainer.style.display = 'block';
            step1.style.display = 'none';
            step2.style.display = 'block';
            step2.scrollIntoView({ behavior: 'smooth' });
        };
        reader.readAsDataURL(file);
    }

    async function fetchSpecs() {
        if (!currentFile) return;
        const formData = new FormData();
        formData.append('file', currentFile);
        formData.append('preset', document.getElementById('presetSelect').value);
        // Use the hidden input or display value for budget
        formData.append('budget', document.getElementById('budgetSelect').value);
        formData.append('zone', document.getElementById('zoneSelect').value);

        showLoader('Designing your space with AI...');
        try {
            const response = await fetch('/api/v1/generate-specs', { method: 'POST', body: formData });
            const data = await response.json();
            if (data.error) throw new Error(data.error);
            tempFilePath = data.temp_file;
            displaySpecs(data.specs);
            configSection.style.display = 'none';
            specSelectionSection.style.display = 'block';
            specSelectionSection.scrollIntoView({ behavior: 'smooth' });
        } catch (error) {
            alert('Error: ' + error.message);
        } finally {
            hideLoader();
        }
    }

    generateSpecsBtn.addEventListener('click', fetchSpecs);
    generateMoreBtn.addEventListener('click', fetchSpecs);

    function displaySpecs(specs) {
        specsGrid.innerHTML = '';
        specs.forEach(spec => {
            const card = document.createElement('div');
            card.className = 'glass-card spec-card';
            card.innerHTML = `
                <img src="${spec.image_url}" class="spec-img" onerror="this.src='https://placehold.co/600x400/f5f5f7/f5f5f7'">
                <h3>${spec.title}</h3>
                <p style="color:var(--text-muted); font-size:0.95rem; margin:15px 0 25px;">${spec.description}</p>
                <div style="margin-top:auto; display:flex; justify-content:space-between; align-items:center;">
                    <div class="tag">Vibe: ${spec.vibe}</div>
                    <button class="btn-primary" style="width:auto; padding: 8px 20px; font-size: 0.85rem; border-radius: 12px;">Select</button>
                </div>
            `;
            card.addEventListener('click', () => selectSpec(spec));
            specsGrid.appendChild(card);
        });
    }

    async function selectSpec(spec) {
        showLoader('Calculating Final Estimations...');
        try {
            const response = await fetch('/api/v1/analyze-selected', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ temp_file: tempFilePath, spec: spec })
            });
            const data = await response.json();
            if (data.error) throw new Error(data.error);

            saveToHistory({
                vision: data.vision_analysis,
                costs: data.cost_estimates,
                spec: spec,
                full_data: data
            });

            displayFinalResults(data);
            specSelectionSection.style.display = 'none';
            resultsContainer.style.display = 'block';
            resultsContainer.scrollIntoView({ behavior: 'smooth' });
        } catch (error) {
            alert('Error: ' + error.message);
        } finally {
            hideLoader();
        }
    }

    function displayFinalResults(data) {
        const vision = data.vision_analysis;
        const costs = data.cost_estimates;
        const business = data.business_classification;
        const spec = data.selected_spec;

        finalDesignImage.src = spec.image_url || '';
        finalDesignTitle.innerText = spec.title || 'Custom Design';
        finalDesignVibe.innerText = `Direction: ${spec.vibe || 'Unique'}`;

        document.getElementById('visionData').innerHTML = `
            <div class="data-row"><span class="data-label">Detected Room</span><span class="data-value">${vision.room_type || 'Unknown'}</span></div>
            <div class="data-row"><span class="data-label">Selected Style</span><span class="data-value">${vision.style_guess || 'Modern'}</span></div>
            <div class="data-row"><span class="data-label">Quality Level</span><span class="data-value">${vision.quality_tier_guess?.tier || 'Premium'}</span></div>
            <div style="margin-top:25px;">
                <p style="color:var(--text-muted); font-size:0.9rem; margin-bottom:12px; font-weight: 600;">Execution Strategy:</p>
                <ul style="padding-left:20px; font-size:0.9rem; color:var(--text-main); line-height:1.7;">
                    ${(vision.cost_saving_points || []).map(p => `<li style="margin-bottom:8px;">${p}</li>`).join('')}
                </ul>
            </div>
        `;

        const premium = costs.premium;
        document.getElementById('costData').innerHTML = `
            <div class="data-row"><span class="data-label">Materials Subtotal</span><span class="data-value">₹${premium.subtotal.toLocaleString()}</span></div>
            <div class="data-row"><span class="data-label">Labor & Installation</span><span class="data-value">₹${premium.labor.toLocaleString()}</span></div>
            <div class="data-row"><span class="data-label">Contingency Fund</span><span class="data-value">₹${premium.contingency.toLocaleString()}</span></div>
            <div class="price-tier">
                <p style="font-size:0.85rem; color:var(--text-muted); font-weight: 600;">ESTIMATED TOTAL BUDGET</p>
                <p class="total-price">₹${premium.total.toLocaleString()}</p>
            </div>
        `;

        document.getElementById('businessData').innerHTML = `
            <div class="data-row"><span class="data-label">Project Complexity</span><span class="data-value">${business.complexity_assessment || 'Standard'}</span></div>
            <div class="data-row"><span class="data-label">Market Segment</span><span class="data-value">${business.customer_segment || 'Premium'}</span></div>
            <div style="margin-top:25px; padding:20px; border-radius:16px; background: var(--primary-glow);">
                <p style="font-size:0.85rem; margin-bottom:8px; font-weight: 600; color: var(--text-muted);">Business Priority:</p>
                <p style="font-size:1.1rem; font-weight:700; color:var(--primary);">${business.business_priority || 'High Priority'}</p>
            </div>
        `;
    }

    function showLoader(text) {
        loader.querySelector('p').innerText = text;
        loader.style.display = 'flex';
    }

    function hideLoader() {
        loader.style.display = 'none';
    }

    // Init
    checkAuth();
});

from PySide6.QtWidgets import (QApplication, QMainWindow, QWidget, QHBoxLayout, 
                             QVBoxLayout, QListWidget, QGroupBox, QLabel, 
                             QLineEdit, QTextEdit, QPushButton, QSpinBox,
                             QComboBox, QListWidgetItem, QScrollArea)
from PySide6.QtCore import Qt
import json
import sys

# 预设配置
SKILL_PRESETS = {
    # 技能标签预设
    "tags": [
        "enemy_only",    # 仅能对敌人使用
        "ally_only",     # 仅能对友军使用
        "ranged",        # 远程技能
        "row",           # 影响整行
        "column"         # 影响整列
    ],
    
    # 使用条件类型预设
    "condition_types": [
        "mp_cost",       # 魔法消耗
        "hp_cost",       # 生命消耗
        "qi_cost",       # 气力消耗
        "cooldown",      # 冷却时间
        "level_required" # 等级要求
    ],
    
    # 效果类型预设
    "effect_types": [
        "magic_damage",    # 魔法伤害
        "physical_damage", # 物理伤害
        "heal",           # 治疗
        "status"          # 状态效果
    ],
    
    # 状态效果类型预设
    "status_types": [
        "burn",          # 燃烧
        "slow",          # 减速
        "stun",          # 眩晕
        "poison",        # 中毒
        "freeze"         # 冻结
    ],
    
    # 数值范围预设
    "value_ranges": {
        "priority": {"min": 0, "max": 10},      # 优先级范围
        "damage": {"min": 0, "max": 9999},      # 伤害范围
        "mp_cost": {"min": 0, "max": 999},      # MP消耗范围
        "duration": {"min": 1, "max": 10}       # 持续时间范围
    }
}

class SkillEditor(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("技能编辑器")
        self.setMinimumSize(1000, 800)
        
        # 加载技能数据
        with open("Dataset/Skills.json", "r", encoding="utf-8") as f:
            self.skills_data = json.load(f)
        
        self.setup_ui()
    
    def setup_ui(self):
        # 创建主布局
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        layout = QHBoxLayout(main_widget)
        
        # 左侧技能列表
        self.setup_skill_list(layout)
        
        # 右侧详细信息
        self.setup_detail_panel(layout)
        
        # 连接效果类型改变事件
        self.effect_type_combo.currentTextChanged.connect(self.on_effect_type_changed)
    
    def setup_skill_list(self, parent_layout):
        self.skill_list = QListWidget()
        self.skill_list.setMaximumWidth(200)
        for skill_id, skill in self.skills_data.items():
            self.skill_list.addItem(f"{skill_id}: {skill['name']}")
        self.skill_list.currentRowChanged.connect(self.show_skill_details)
        parent_layout.addWidget(self.skill_list)
    
    def setup_detail_panel(self, parent_layout):
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        self.detail_widget = QWidget()
        scroll.setWidget(self.detail_widget)
        detail_layout = QVBoxLayout(self.detail_widget)
        
        # 添加各个组件
        self.setup_basic_info(detail_layout)
        self.setup_tags(detail_layout)
        self.setup_conditions(detail_layout)
        self.setup_effects(detail_layout)
        
        # 保存按钮
        save_btn = QPushButton("保存修改")
        save_btn.clicked.connect(self.save_changes)
        detail_layout.addWidget(save_btn)
        
        parent_layout.addWidget(scroll)
        self.detail_widget.hide()
    
    def setup_basic_info(self, parent_layout):
        basic_group = QGroupBox("基础信息")
        basic_layout = QVBoxLayout(basic_group)
        
        self.name_edit = QLineEdit()
        self.desc_edit = QTextEdit()
        self.priority_spin = QSpinBox()
        self.priority_spin.setRange(
            SKILL_PRESETS["value_ranges"]["priority"]["min"],
            SKILL_PRESETS["value_ranges"]["priority"]["max"]
        )
        self.animation_edit = QLineEdit()
        
        basic_layout.addWidget(QLabel("名称:"))
        basic_layout.addWidget(self.name_edit)
        basic_layout.addWidget(QLabel("描述:"))
        basic_layout.addWidget(self.desc_edit)
        basic_layout.addWidget(QLabel("优先级:"))
        basic_layout.addWidget(self.priority_spin)
        basic_layout.addWidget(QLabel("动画:"))
        basic_layout.addWidget(self.animation_edit)
        
        parent_layout.addWidget(basic_group)
    
    def setup_tags(self, parent_layout):
        tag_group = QGroupBox("标签")
        tag_layout = QVBoxLayout(tag_group)
        
        self.tag_list = QListWidget()
        self.tag_combo = QComboBox()
        self.tag_combo.addItems(SKILL_PRESETS["tags"])
        
        add_tag_btn = QPushButton("添加标签")
        add_tag_btn.clicked.connect(self.add_tag)
        remove_tag_btn = QPushButton("删除选中标签")
        remove_tag_btn.clicked.connect(self.remove_tag)
        
        tag_layout.addWidget(self.tag_list)
        tag_layout.addWidget(self.tag_combo)
        tag_layout.addWidget(add_tag_btn)
        tag_layout.addWidget(remove_tag_btn)
        
        parent_layout.addWidget(tag_group)
    
    def setup_conditions(self, parent_layout):
        condition_group = QGroupBox("使用条件")
        condition_layout = QVBoxLayout(condition_group)
        
        self.condition_list = QListWidget()
        condition_add_layout = QHBoxLayout()
        
        self.condition_type_combo = QComboBox()
        self.condition_type_combo.addItems(SKILL_PRESETS["condition_types"])
        
        self.condition_value_spin = QSpinBox()
        self.condition_value_spin.setRange(
            SKILL_PRESETS["value_ranges"]["mp_cost"]["min"],
            SKILL_PRESETS["value_ranges"]["mp_cost"]["max"]
        )
        
        add_condition_btn = QPushButton("添加条件")
        add_condition_btn.clicked.connect(self.add_condition)
        remove_condition_btn = QPushButton("删除选中条件")
        remove_condition_btn.clicked.connect(self.remove_condition)
        
        condition_add_layout.addWidget(self.condition_type_combo)
        condition_add_layout.addWidget(self.condition_value_spin)
        condition_add_layout.addWidget(add_condition_btn)
        
        condition_layout.addWidget(self.condition_list)
        condition_layout.addLayout(condition_add_layout)
        condition_layout.addWidget(remove_condition_btn)
        
        parent_layout.addWidget(condition_group)
    
    def setup_effects(self, parent_layout):
        effect_group = QGroupBox("效果")
        effect_layout = QVBoxLayout(effect_group)
        
        self.effect_list = QListWidget()
        effect_add_layout = QHBoxLayout()
        
        self.effect_type_combo = QComboBox()
        self.effect_type_combo.addItems(SKILL_PRESETS["effect_types"])
        
        self.status_type_combo = QComboBox()
        self.status_type_combo.addItems(SKILL_PRESETS["status_types"])
        self.status_type_combo.hide()
        
        self.effect_value_spin = QSpinBox()
        self.effect_value_spin.setRange(
            SKILL_PRESETS["value_ranges"]["damage"]["min"],
            SKILL_PRESETS["value_ranges"]["damage"]["max"]
        )
        
        add_effect_btn = QPushButton("添加效果")
        add_effect_btn.clicked.connect(self.add_effect)
        remove_effect_btn = QPushButton("删除选中效果")
        remove_effect_btn.clicked.connect(self.remove_effect)
        
        effect_add_layout.addWidget(self.effect_type_combo)
        effect_add_layout.addWidget(self.status_type_combo)
        effect_add_layout.addWidget(self.effect_value_spin)
        effect_add_layout.addWidget(add_effect_btn)
        
        effect_layout.addWidget(self.effect_list)
        effect_layout.addLayout(effect_add_layout)
        effect_layout.addWidget(remove_effect_btn)
        
        parent_layout.addWidget(effect_group)

    def show_skill_details(self, row):
        if row < 0:
            self.detail_widget.hide()
            return
            
        self.detail_widget.show()
        skill_id = list(self.skills_data.keys())[row]
        skill = self.skills_data[skill_id]
        
        self.current_skill_id = skill_id
        
        # 更新基础信息
        self.name_edit.setText(skill['name'])
        self.desc_edit.setText(skill['description'])
        self.priority_spin.setValue(skill.get('priority', 0))
        self.animation_edit.setText(skill.get('animation', ''))
        
        # 更新标签列表
        self.tag_list.clear()
        for tag in skill.get('tag', []):
            self.tag_list.addItem(tag)
            
        # 更新条件列表
        self.condition_list.clear()
        for condition in skill.get('use_conditions', []):
            self.condition_list.addItem(
                f"{condition['type']}: {condition['value']}"
            )
            
        # 更新效果列表
        self.effect_list.clear()
        for effect in skill.get('effects', []):
            if effect['type'] == 'status':
                self.effect_list.addItem(
                    f"{effect['type']} - {effect['status_type']}: {effect['value']}"
                )
            else:
                self.effect_list.addItem(
                    f"{effect['type']}: {effect['value']}"
                )

    def add_tag(self):
        tag = self.tag_combo.currentText()
        if tag not in [self.tag_list.item(i).text() for i in range(self.tag_list.count())]:
            self.tag_list.addItem(tag)

    def remove_tag(self):
        if self.tag_list.currentItem():
            self.tag_list.takeItem(self.tag_list.currentRow())

    def add_condition(self):
        condition_type = self.condition_type_combo.currentText()
        value = self.condition_value_spin.value()
        self.condition_list.addItem(f"{condition_type}: {value}")

    def remove_condition(self):
        if self.condition_list.currentItem():
            self.condition_list.takeItem(self.condition_list.currentRow())

    def on_effect_type_changed(self, effect_type):
        self.status_type_combo.setVisible(effect_type == "status")

    def add_effect(self):
        effect_type = self.effect_type_combo.currentText()
        value = self.effect_value_spin.value()
        
        if effect_type == "status":
            status_type = self.status_type_combo.currentText()
            self.effect_list.addItem(f"{effect_type} - {status_type}: {value}")
        else:
            self.effect_list.addItem(f"{effect_type}: {value}")

    def remove_effect(self):
        if self.effect_list.currentItem():
            self.effect_list.takeItem(self.effect_list.currentRow())

    def save_changes(self):
        if not hasattr(self, 'current_skill_id'):
            return
            
        skill = self.skills_data[self.current_skill_id]
        
        # 保存基础信息
        skill['name'] = self.name_edit.text()
        skill['description'] = self.desc_edit.toPlainText()
        if self.priority_spin.value() > 0:
            skill['priority'] = self.priority_spin.value()
        skill['animation'] = self.animation_edit.text()
        
        # 保存标签
        skill['tag'] = [self.tag_list.item(i).text() 
                       for i in range(self.tag_list.count())]
        
        # 保存条件
        skill['use_conditions'] = []
        for i in range(self.condition_list.count()):
            condition_text = self.condition_list.item(i).text()
            condition_type, value = condition_text.split(': ')
            skill['use_conditions'].append({
                'type': condition_type,
                'value': int(value)
            })
        
        # 保存效果
        skill['effects'] = []
        for i in range(self.effect_list.count()):
            effect_text = self.effect_list.item(i).text()
            if ' - ' in effect_text:
                # 状态效果
                effect_type, rest = effect_text.split(' - ')
                status_type, value = rest.split(': ')
                skill['effects'].append({
                    'type': effect_type,
                    'status_type': status_type,
                    'value': int(value)
                })
            else:
                # 普通效果
                effect_type, value = effect_text.split(': ')
                skill['effects'].append({
                    'type': effect_type,
                    'value': int(value)
                })
        
        # 更新列表显示
        current_item = self.skill_list.currentItem()
        current_item.setText(f"{self.current_skill_id}: {skill['name']}")
        
        # 保存到文件
        with open("Dataset/Skills.json", "w", encoding="utf-8") as f:
            json.dump(self.skills_data, f, ensure_ascii=False, indent=2)

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = SkillEditor()
    window.show()
    sys.exit(app.exec())

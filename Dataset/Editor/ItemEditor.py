from PySide6.QtWidgets import (QApplication, QMainWindow, QWidget, QHBoxLayout, 
                             QVBoxLayout, QListWidget, QGroupBox, QLabel, 
                             QLineEdit, QTextEdit, QPushButton, QSpinBox,
                             QComboBox, QListWidgetItem, QScrollArea, QTabWidget)
from PySide6.QtCore import Qt
import json
import sys

# 预设配置
ITEM_PRESETS = {
    # 装备类型预设
    "equipment_types": [
        "weapon",
        "armor",
        "accessory"
    ],
    
    # 装备标签预设
    "equipment_tags": [
        "melee",
        "magic",
        "ranged",
        "lightarmor",
        "heavyarmor",
        "boot",
        "necklace",
        "bracelet",
        "ring",
        "amulet"
    ],
    
    # 将属性类型分为基础属性和战斗属性
    "base_attributes": [
        "strength",
        "dexterity",
        "constitution",
        "intelligence",
        "perception",
        "charisma",
        "max_health",
        "max_mana"
    ],
    
    "combat_attributes": [
        "physical_attack",
        "magical_attack",
        "physical_defense",
        "magical_defense",

    ],
    
    # 消耗品类型预设
    "consumable_categories": [
        "food",
        "potion"
    ],
    
    # 消耗品使用类型预设
    "use_types": [
        "all_time",
        "battle",
        "non_battle"
    ],
    
    # 消耗品效果类型预设
    "effect_types": [
        "heal",
        "gain_energy"
    ],
    
    # 杂项物品类别预设
    "misc_categories": [
        "制作材料",
        "情报物品",
        "钥匙",
        "收藏品"
    ],
    
    # 数值范围预设
    "value_ranges": {
        "item_value": {"min": 0, "max": 9999},
        "attribute": {"min": 0, "max": 99}
    }
}

class ItemEditor(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("道具编辑器")
        self.setMinimumSize(1200, 800)
        
        # 加载所有道具数据
        self.load_data()
        
        # 创建主布局
        self.setup_ui()
    
    def load_data(self):
        """加载所有道具数据"""
        with open("Dataset/Item/ItemEquipment.json", "r", encoding="utf-8") as f:
            self.equipment_data = json.load(f)
        with open("Dataset/Item/ItemConsumable.json", "r", encoding="utf-8") as f:
            self.consumable_data = json.load(f)
        with open("Dataset/Item/ItemMisc.json", "r", encoding="utf-8") as f:
            self.misc_data = json.load(f)
    
    def setup_ui(self):
        """设置主界面"""
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        layout = QHBoxLayout(main_widget)
        
        # 创建标签页
        tab_widget = QTabWidget()
        
        # 装备标签页
        equipment_tab = self.create_equipment_tab()
        tab_widget.addTab(equipment_tab, "装备")
        
        # 消耗品标签页
        consumable_tab = self.create_consumable_tab()
        tab_widget.addTab(consumable_tab, "消耗品")
        
        # 杂项标签页
        misc_tab = self.create_misc_tab()
        tab_widget.addTab(misc_tab, "杂项")
        
        layout.addWidget(tab_widget)
    
    def create_equipment_tab(self):
        """创建装备标签页"""
        tab = QWidget()
        layout = QHBoxLayout(tab)
        
        # 左侧列表
        self.equipment_list = QListWidget()
        self.equipment_list.setMaximumWidth(200)
        for item_id, item in self.equipment_data.items():
            self.equipment_list.addItem(f"{item_id}: {item['name']}")
        self.equipment_list.currentRowChanged.connect(self.show_equipment_details)
        layout.addWidget(self.equipment_list)
        
        # 右侧详细信息
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        self.equipment_detail = QWidget()
        scroll.setWidget(self.equipment_detail)
        detail_layout = QVBoxLayout(self.equipment_detail)
        
        # 基础信息组
        basic_group = QGroupBox("基础信息")
        basic_layout = QVBoxLayout(basic_group)
        
        self.equipment_name = QLineEdit()
        self.equipment_desc = QTextEdit()
        self.equipment_value = QSpinBox()
        self.equipment_value.setRange(
            ITEM_PRESETS["value_ranges"]["item_value"]["min"],
            ITEM_PRESETS["value_ranges"]["item_value"]["max"]
        )
        self.equipment_type = QComboBox()
        self.equipment_type.addItems(ITEM_PRESETS["equipment_types"])
        self.equipment_tag = QComboBox()
        self.equipment_tag.addItems(ITEM_PRESETS["equipment_tags"])
        
        basic_layout.addWidget(QLabel("名称:"))
        basic_layout.addWidget(self.equipment_name)
        basic_layout.addWidget(QLabel("描述:"))
        basic_layout.addWidget(self.equipment_desc)
        basic_layout.addWidget(QLabel("价值:"))
        basic_layout.addWidget(self.equipment_value)
        basic_layout.addWidget(QLabel("类型:"))
        basic_layout.addWidget(self.equipment_type)
        basic_layout.addWidget(QLabel("标签:"))
        basic_layout.addWidget(self.equipment_tag)
        
        detail_layout.addWidget(basic_group)
        
        # 属性加成组
        attribute_group = QGroupBox("属性加成")
        attribute_layout = QVBoxLayout(attribute_group)
        self.attribute_list = QListWidget()
        
        attribute_add_layout = QHBoxLayout()
        self.attribute_type = QComboBox()
        all_attributes = ITEM_PRESETS["base_attributes"] + ITEM_PRESETS["combat_attributes"]
        self.attribute_type.addItems(all_attributes)
        
        # 添加最小值和最大值输入框
        self.attribute_min = QSpinBox()
        self.attribute_min.setRange(
            ITEM_PRESETS["value_ranges"]["attribute"]["min"],
            ITEM_PRESETS["value_ranges"]["attribute"]["max"]
        )
        self.attribute_max = QSpinBox()
        self.attribute_max.setRange(
            ITEM_PRESETS["value_ranges"]["attribute"]["min"],
            ITEM_PRESETS["value_ranges"]["attribute"]["max"]
        )
        
        # 确保先添加所有控件到布局
        attribute_add_layout.addWidget(QLabel("属性:"))
        attribute_add_layout.addWidget(self.attribute_type)
        attribute_add_layout.addWidget(QLabel("最小值:"))
        attribute_add_layout.addWidget(self.attribute_min)
        attribute_add_layout.addWidget(QLabel("最大值:"))
        attribute_add_layout.addWidget(self.attribute_max)
        
        # 然后再连接信号并初始化状态
        self.attribute_type.currentTextChanged.connect(self.on_attribute_type_changed)
        # 强制触发一次状态更新
        self.on_attribute_type_changed(self.attribute_type.currentText())
        
        add_attribute_btn = QPushButton("添加属性")
        add_attribute_btn.clicked.connect(self.add_attribute)
        remove_attribute_btn = QPushButton("删除属性")
        remove_attribute_btn.clicked.connect(self.remove_attribute)
        
        attribute_add_layout.addWidget(add_attribute_btn)
        
        attribute_layout.addWidget(self.attribute_list)
        attribute_layout.addLayout(attribute_add_layout)
        attribute_layout.addWidget(remove_attribute_btn)
        
        detail_layout.addWidget(attribute_group)
        
        # 添加装备条件组
        condition_group = QGroupBox("装备条件")
        condition_layout = QVBoxLayout(condition_group)
        self.condition_list = QListWidget()
        
        condition_add_layout = QHBoxLayout()
        self.condition_type = QComboBox()
        self.condition_type.addItems(["strength", "intelligence", "dexterity"])
        self.condition_value = QSpinBox()
        self.condition_value.setRange(0, 99)
        
        add_condition_btn = QPushButton("添加条件")
        add_condition_btn.clicked.connect(self.add_equip_condition)
        remove_condition_btn = QPushButton("删除条件")
        remove_condition_btn.clicked.connect(self.remove_equip_condition)
        
        condition_add_layout.addWidget(QLabel("属性:"))
        condition_add_layout.addWidget(self.condition_type)
        condition_add_layout.addWidget(QLabel("要求值:"))
        condition_add_layout.addWidget(self.condition_value)
        condition_add_layout.addWidget(add_condition_btn)
        
        condition_layout.addWidget(self.condition_list)
        condition_layout.addLayout(condition_add_layout)
        condition_layout.addWidget(remove_condition_btn)
        
        detail_layout.addWidget(condition_group)
        
        # 添加特殊技能组
        skill_group = QGroupBox("特殊技能")
        skill_layout = QVBoxLayout(skill_group)
        self.skill_list = QListWidget()
        
        skill_add_layout = QHBoxLayout()
        self.skill_id = QLineEdit()
        self.skill_id.setPlaceholderText("输入技能ID")
        
        add_skill_btn = QPushButton("添加技能")
        add_skill_btn.clicked.connect(self.add_special_skill)
        remove_skill_btn = QPushButton("删除技能")
        remove_skill_btn.clicked.connect(self.remove_special_skill)
        
        skill_add_layout.addWidget(QLabel("技能ID:"))
        skill_add_layout.addWidget(self.skill_id)
        skill_add_layout.addWidget(add_skill_btn)
        
        skill_layout.addWidget(self.skill_list)
        skill_layout.addLayout(skill_add_layout)
        skill_layout.addWidget(remove_skill_btn)
        
        detail_layout.addWidget(skill_group)
        
        # 添加图像路径
        image_group = QGroupBox("图像")
        image_layout = QVBoxLayout(image_group)
        self.image_path = QLineEdit()
        image_layout.addWidget(QLabel("图像路径:"))
        image_layout.addWidget(self.image_path)
        
        detail_layout.addWidget(image_group)
        
        # 保存按钮
        save_btn = QPushButton("保存修改")
        save_btn.clicked.connect(self.save_equipment)
        detail_layout.addWidget(save_btn)
        
        layout.addWidget(scroll)
        return tab

    def create_consumable_tab(self):
        """创建消耗品标签页"""
        tab = QWidget()
        layout = QHBoxLayout(tab)
        
        # 左侧列表
        self.consumable_list = QListWidget()
        self.consumable_list.setMaximumWidth(200)
        for item_id, item in self.consumable_data.items():
            self.consumable_list.addItem(f"{item_id}: {item['name']}")
        self.consumable_list.currentRowChanged.connect(self.show_consumable_details)
        layout.addWidget(self.consumable_list)
        
        # 右侧详细信息
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        self.consumable_detail = QWidget()
        scroll.setWidget(self.consumable_detail)
        detail_layout = QVBoxLayout(self.consumable_detail)
        
        # 基础信息组
        basic_group = QGroupBox("基础信息")
        basic_layout = QVBoxLayout(basic_group)
        
        self.consumable_name = QLineEdit()
        self.consumable_desc = QTextEdit()
        self.consumable_value = QSpinBox()
        self.consumable_value.setRange(0, 9999)
        self.consumable_category = QComboBox()
        self.consumable_category.addItems(ITEM_PRESETS["consumable_categories"])
        self.consumable_use_type = QComboBox()
        self.consumable_use_type.addItems(ITEM_PRESETS["use_types"])
        
        basic_layout.addWidget(QLabel("名称:"))
        basic_layout.addWidget(self.consumable_name)
        basic_layout.addWidget(QLabel("描述:"))
        basic_layout.addWidget(self.consumable_desc)
        basic_layout.addWidget(QLabel("价值:"))
        basic_layout.addWidget(self.consumable_value)
        basic_layout.addWidget(QLabel("类别:"))
        basic_layout.addWidget(self.consumable_category)
        basic_layout.addWidget(QLabel("使用类型:"))
        basic_layout.addWidget(self.consumable_use_type)
        
        detail_layout.addWidget(basic_group)
        
        # 效果组
        effect_group = QGroupBox("效果")
        effect_layout = QVBoxLayout(effect_group)
        
        self.effect_type = QComboBox()
        self.effect_type.addItems(ITEM_PRESETS["effect_types"])
        self.effect_value = QSpinBox()
        self.effect_value.setRange(0, 999)
        
        effect_layout.addWidget(QLabel("效果类型:"))
        effect_layout.addWidget(self.effect_type)
        effect_layout.addWidget(QLabel("效果值:"))
        effect_layout.addWidget(self.effect_value)
        
        detail_layout.addWidget(effect_group)
        
        # 保存按钮
        save_btn = QPushButton("保存修改")
        save_btn.clicked.connect(self.save_consumable)
        detail_layout.addWidget(save_btn)
        
        layout.addWidget(scroll)
        return tab

    def create_misc_tab(self):
        """创建杂项物品标签页"""
        tab = QWidget()
        layout = QHBoxLayout(tab)
        
        # 左侧列表
        self.misc_list = QListWidget()
        self.misc_list.setMaximumWidth(200)
        for item_id, item in self.misc_data.items():
            self.misc_list.addItem(f"{item_id}: {item['name']}")
        self.misc_list.currentRowChanged.connect(self.show_misc_details)
        layout.addWidget(self.misc_list)
        
        # 右侧详细信息
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        self.misc_detail = QWidget()
        scroll.setWidget(self.misc_detail)
        detail_layout = QVBoxLayout(self.misc_detail)
        
        # 基础信息组
        basic_group = QGroupBox("基础信息")
        basic_layout = QVBoxLayout(basic_group)
        
        self.misc_name = QLineEdit()
        self.misc_desc = QTextEdit()
        self.misc_value = QSpinBox()
        self.misc_value.setRange(0, 9999)
        self.misc_category = QComboBox()
        self.misc_category.addItems(ITEM_PRESETS["misc_categories"])
        
        basic_layout.addWidget(QLabel("名称:"))
        basic_layout.addWidget(self.misc_name)
        basic_layout.addWidget(QLabel("描述:"))
        basic_layout.addWidget(self.misc_desc)
        basic_layout.addWidget(QLabel("价值:"))
        basic_layout.addWidget(self.misc_value)
        basic_layout.addWidget(QLabel("类别:"))
        basic_layout.addWidget(self.misc_category)
        
        detail_layout.addWidget(basic_group)
        
        # 保存按钮
        save_btn = QPushButton("保存修改")
        save_btn.clicked.connect(self.save_misc)
        detail_layout.addWidget(save_btn)
        
        layout.addWidget(scroll)
        return tab

    def show_equipment_details(self, row):
        """显示装备详细信息"""
        if row < 0:
            return
            
        item_id = list(self.equipment_data.keys())[row]
        item = self.equipment_data[item_id]
        
        self.current_equipment_id = item_id
        
        # 更新基础信息
        self.equipment_name.setText(item['name'])
        self.equipment_desc.setText(item['description'])
        self.equipment_value.setValue(item['item_value'])
        self.equipment_type.setCurrentText(item['equipment_type'])
        self.equipment_tag.setCurrentText(item['tag'])
        
        # 更新属性列表
        self.attribute_list.clear()
        for attr, value in item['attribute_boosts'].items():
            if attr in ITEM_PRESETS["base_attributes"]:
                # 基础属性显示固定值
                self.attribute_list.addItem(f"{attr}: {value}")
            else:
                # 战斗属性显示区间
                if isinstance(value, dict):
                    self.attribute_list.addItem(f"{attr}: {value['min']}-{value['max']}")
                else:
                    # 处理可能的旧数据格式
                    self.attribute_list.addItem(f"{attr}: {value}")
        
        # 更新装备条件列表
        self.condition_list.clear()
        for attr, value in item.get('equip_conditions', {}).items():
            self.condition_list.addItem(f"{attr}: {value}")
        
        # 更新特殊技能列表
        self.skill_list.clear()
        for skill_id in item.get('special_skill', []):
            self.skill_list.addItem(str(skill_id))
        
        # 更新图像路径
        self.image_path.setText(item.get('image', ''))

    def show_consumable_details(self, row):
        """显示消耗品详细信息"""
        if row < 0:
            return
            
        item_id = list(self.consumable_data.keys())[row]
        item = self.consumable_data[item_id]
        
        self.current_consumable_id = item_id
        
        # 更新基础信息
        self.consumable_name.setText(item['name'])
        self.consumable_desc.setText(item['description'])
        self.consumable_value.setValue(item['item_value'])
        self.consumable_category.setCurrentText(item['category'])
        self.consumable_use_type.setCurrentText(item['use_type'])
        
        # 更新效果信息
        self.effect_type.setCurrentText(item['effects']['type'])
        self.effect_value.setValue(item['effects']['value'])

    def show_misc_details(self, row):
        """显示杂项物品详细信息"""
        if row < 0:
            return
            
        item_id = list(self.misc_data.keys())[row]
        item = self.misc_data[item_id]
        
        self.current_misc_id = item_id
        
        # 更新基础信息
        self.misc_name.setText(item['name'])
        self.misc_desc.setText(item['description'])
        self.misc_value.setValue(item['item_value'])
        self.misc_category.setCurrentText(item['category'])

    def add_attribute(self):
        """添加属性"""
        attr_type = self.attribute_type.currentText()
        min_val = self.attribute_min.value()
        max_val = self.attribute_max.value()
        
        # 区分基础属性和战斗属性的处理
        if attr_type in ITEM_PRESETS["base_attributes"]:
            # 基础属性只使用固定值（使用min_val）
            self.attribute_list.addItem(f"{attr_type}: {min_val}")
        else:
            # 战斗属性使用随机区间
            if min_val > max_val:
                min_val, max_val = max_val, min_val
            self.attribute_list.addItem(f"{attr_type}: {min_val}-{max_val}")

    def remove_attribute(self):
        """删除属性"""
        if self.attribute_list.currentItem():
            self.attribute_list.takeItem(self.attribute_list.currentRow())

    def add_equip_condition(self):
        """添加装备条件"""
        condition_type = self.condition_type.currentText()
        value = self.condition_value.value()
        self.condition_list.addItem(f"{condition_type}: {value}")

    def remove_equip_condition(self):
        """删除装备条件"""
        if self.condition_list.currentItem():
            self.condition_list.takeItem(self.condition_list.currentRow())

    def add_special_skill(self):
        """添加特殊技能"""
        skill_id = self.skill_id.text().strip()
        if skill_id.isdigit():
            self.skill_list.addItem(skill_id)
            self.skill_id.clear()

    def remove_special_skill(self):
        """删除特殊技能"""
        if self.skill_list.currentItem():
            self.skill_list.takeItem(self.skill_list.currentRow())

    def save_equipment(self):
        """保存装备数据"""
        if not hasattr(self, 'current_equipment_id'):
            return
            
        item = self.equipment_data[self.current_equipment_id]
        
        # 保存基础信息
        item['name'] = self.equipment_name.text()
        item['description'] = self.equipment_desc.toPlainText()
        item['item_value'] = self.equipment_value.value()
        item['equipment_type'] = self.equipment_type.currentText()
        item['tag'] = self.equipment_tag.currentText()
        
        # 保存属性加成
        item['attribute_boosts'] = {}
        for i in range(self.attribute_list.count()):
            attr_text = self.attribute_list.item(i).text()
            attr_type, value = attr_text.split(': ')
            
            if attr_type in ITEM_PRESETS["base_attributes"]:
                # 基础属性保存为固定值
                item['attribute_boosts'][attr_type] = int(value)
            else:
                # 战斗属保存为区间
                if '-' in value:
                    min_val, max_val = map(int, value.split('-'))
                    item['attribute_boosts'][attr_type] = {"min": min_val, "max": max_val}
                else:
                    # 处理可能的旧数据格式
                    item['attribute_boosts'][attr_type] = {"min": int(value), "max": int(value)}
        
        # 保存装备条件
        item['equip_conditions'] = {}
        for i in range(self.condition_list.count()):
            condition_text = self.condition_list.item(i).text()
            condition_type, value = condition_text.split(': ')
            item['equip_conditions'][condition_type] = int(value)
        
        # 保存特殊技能
        item['special_skill'] = []
        for i in range(self.skill_list.count()):
            skill_id = int(self.skill_list.item(i).text())
            item['special_skill'].append(skill_id)
        
        # 保存图像路径
        image_path = self.image_path.text().strip()
        if image_path:
            item['image'] = image_path
        
        self.save_to_file('equipment')

    def save_consumable(self):
        """保存消耗品数据"""
        if not hasattr(self, 'current_consumable_id'):
            return
            
        item = self.consumable_data[self.current_consumable_id]
        
        # 保存基础信息
        item['name'] = self.consumable_name.text()
        item['description'] = self.consumable_desc.toPlainText()
        item['item_value'] = self.consumable_value.value()
        item['category'] = self.consumable_category.currentText()
        item['use_type'] = self.consumable_use_type.currentText()
        
        # 保存效果
        item['effects'] = {
            'type': self.effect_type.currentText(),
            'value': self.effect_value.value()
        }
        
        self.save_to_file('consumable')

    def save_misc(self):
        """保存杂项物品数据"""
        if not hasattr(self, 'current_misc_id'):
            return
            
        item = self.misc_data[self.current_misc_id]
        
        # 保存基础信息
        item['name'] = self.misc_name.text()
        item['description'] = self.misc_desc.toPlainText()
        item['item_value'] = self.misc_value.value()
        item['category'] = self.misc_category.currentText()
        
        self.save_to_file('misc')

    def save_to_file(self, item_type):
        """保存数据到文件"""
        file_paths = {
            'equipment': "Dataset/Item/ItemEquipment.json",
            'consumable': "Dataset/Item/ItemConsumable.json",
            'misc': "Dataset/Item/ItemMisc.json"
        }
        
        data = {
            'equipment': self.equipment_data,
            'consumable': self.consumable_data,
            'misc': self.misc_data
        }
        
        with open(file_paths[item_type], "w", encoding="utf-8") as f:
            json.dump(data[item_type], f, ensure_ascii=False, indent=2)

    def on_attribute_type_changed(self, attr_type):
        """当属性类型改变时，控制最大值输入框的启用状态"""
        if attr_type in ITEM_PRESETS["base_attributes"]:
            self.attribute_max.setEnabled(False)
            self.attribute_max.setStyleSheet("QSpinBox { background-color: #F0F0F0; color: #808080; }")
            self.attribute_max.setValue(self.attribute_min.value())
        else:
            self.attribute_max.setEnabled(True)
            self.attribute_max.setStyleSheet("")  # 清除样式表，恢复默认外观

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = ItemEditor()
    window.show()
    sys.exit(app.exec())
